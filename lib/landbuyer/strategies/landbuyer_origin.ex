defmodule Landbuyer.Strategies.LandbuyerOrigin do
  @moduledoc """
  Landbuyer Origin strategy.

  1. Get all orders with state PENDING for the given account and for the given instrument.
  2. Compute the low_trade_value and the high_trade_value:
    - If there is no open order, we get the current market price and set low_trade_value and high_trade_value
      to the current price.
    - If there are open TAKE_PROFIT orders, we find the lowest and highest price of the orders from them.
    - If there are open orders but no TAKE_PROFIT orders, we wait for the first executed order.
  3. Compute the list of orders to place:
    - Given a list of MARKET_IF_TOUCHED orders, we compute the list of orders to place.
    - We add the orders that are missing (not already placed).
    - [UNUSED] We remove the orders that are too far from the current price (cleaning).
      We don't use this feature for now because we set orders to auto-expire after 24 hours (GFD orders).
  4. Post the orders.
  """

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @behaviour Strategies

  @spec key() :: atom()
  def key(), do: :landbuyer_origin

  @spec name() :: String.t()
  def name(), do: "Landbuyer Origin"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(account, trader) do
    with {:ok, orders} <- get_open_orders(account, trader),
         {:ok, low_trade, high_trade} <- compute_trade_values(orders, account, trader) do
      orders
      |> compute_orders({low_trade, high_trade}, trader)
      |> post_orders(account, trader)
    end
  end

  @spec get_open_orders(Account.t(), Trader.t()) :: {:ok, list()} | Strategies.events()
  defp get_open_orders(account, trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/orders?state=PENDING&instrument=#{trader.instrument.currency_pair}&count=500",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"orders" => orders}} <- Poison.decode(body) do
      {:ok, orders}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec compute_trade_values(list(), Account.t(), Trader.t()) :: {:ok, float(), float()} | Strategies.events()
  defp compute_trade_values([], account, trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/pricing?instruments=#{trader.instrument.currency_pair}",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"prices" => prices}} <- Poison.decode(body) do
      %{"closeoutAsk" => price} = hd(prices)
      price = format_float(price, trader)
      {:ok, price, price}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  defp compute_trade_values(orders, _account, %{instrument: instr, options: options} = trader) do
    orders = Enum.filter(orders, fn %{"type" => type} -> type == "TAKE_PROFIT" end)

    if length(orders) > 0 do
      price_divider = :math.pow(10, instr.round_decimal)
      dist_on_take_profit = options.distance_on_take_profit / price_divider

      %{"price" => low_trade} = Enum.min_by(orders, fn %{"price" => price} -> String.to_float(price) end)
      %{"price" => high_trade} = Enum.max_by(orders, fn %{"price" => price} -> String.to_float(price) end)

      low_trade = format_float(low_trade, trader) - dist_on_take_profit
      high_trade = format_float(high_trade, trader) - dist_on_take_profit

      {:ok, low_trade, high_trade}
    else
      [{:nothing, :waiting_for_first_executed_order, %{}}]
    end
  end

  @spec compute_orders(list(), {float(), float()}, Trader.t()) :: list()
  defp compute_orders(orders, {low_trade, high_trade}, %{instrument: instr, options: options} = trader) do
    price_divider = :math.pow(10, instr.round_decimal)
    dist_on_take_profit = options.distance_on_take_profit / price_divider
    step_size = options.distance_between_position / price_divider
    order_range = (options.max_order + 1) * step_size
    high_limit = high_trade + order_range
    low_limit = low_trade - order_range

    {_orders_to_remove, orders_to_keep} =
      orders
      |> Enum.filter(fn %{"type" => type} -> type == "MARKET_IF_TOUCHED" end)
      |> Enum.map(fn order -> %{order | "price" => format_float(order["price"], trader)} end)
      |> Enum.split_with(fn %{"price" => price} -> price > high_limit or price < low_limit end)

    1..options.max_order
    |> Enum.flat_map(fn i -> [low_trade - i * step_size, high_trade + i * step_size] end)
    |> Enum.map(fn price -> format_float(price, trader) end)
    |> Enum.reject(fn price -> Enum.any?(orders_to_keep, fn order_price -> order_price == price end) end)
    |> Enum.map(fn price ->
      tp_price = format_float_to_string(price + dist_on_take_profit, trader)
      price = format_float_to_string(price, trader)

      %{
        type: "MARKET_IF_TOUCHED",
        instrument: instr.currency_pair,
        units: options.position_amount,
        price: price,
        timeInForce: "GFD",
        takeProfitOnFill: %{
          timeInForce: "GTC",
          price: tp_price
        }
      }
    end)
  end

  @spec post_orders(list(), Account.t(), Trader.t()) :: Strategies.events()
  defp post_orders([], _account, _trader) do
    [{:nothing, :no_orders_to_place, %{}}]
  end

  defp post_orders(orders, account, trader) do
    opts = [timeout: trader.rate_ms, on_timeout: :kill_task, zip_input_on_exit: true]

    orders
    |> Task.async_stream(&post_order(&1, account, trader), opts)
    |> Enum.map(fn
      {:ok, response} -> response
      {:exit, {{:ok, _response}, reason}} -> {:error, :task_error, %{reason: reason}}
    end)
  end

  @spec post_order(map(), Account.t(), Trader.t()) :: Strategies.event()
  defp post_order(order, account, trader) do
    request = %HTTPoison.Request{
      method: :post,
      url: "https://#{account.hostname}/v3/accounts/#{account.oanda_id}/orders",
      headers: [
        {"Authorization", "Bearer #{account.token}"},
        {"Content-Type", "application/json"}
      ],
      options: [timeout: trader.rate_ms],
      body: Poison.encode!(%{"order" => order})
    }

    case HTTPoison.request(request) do
      {:ok, %HTTPoison.Response{status_code: 201, headers: headers}} ->
        {_, request_id} = Enum.find(headers, fn {key, _value} -> key == "RequestID" end)
        {:success, :order_placed, %{request_id: String.to_integer(request_id)}}

      poison_error ->
        handle_poison_error(poison_error)
    end
  end

  # Helpers

  defp format_float(price, trader) when is_binary(price) do
    price
    |> String.to_float()
    |> Float.round(trader.instrument.round_decimal)
  end

  defp format_float(price, trader) do
    Float.round(price, trader.instrument.round_decimal)
  end

  defp format_float_to_string(price, trader) do
    price
    |> format_float(trader)
    |> Float.to_string()
    |> String.slice(0..(2 + trader.instrument.round_decimal))
  end

  defp handle_poison_error(poison_error) do
    case poison_error do
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, :wrong_http_code, %{status_code: code}}

      {:ok, %HTTPoison.Response{} = poison_response} ->
        {:error, :bad_http_response, Map.from_struct(poison_response)}

      {:error, poison_error} ->
        {:error, :poison_error, Map.from_struct(poison_error)}
    end
  end
end
