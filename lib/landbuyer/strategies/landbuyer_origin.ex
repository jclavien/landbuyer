defmodule Landbuyer.Strategies.LandbuyerOrigin do
  @moduledoc false

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
         {:ok, low_trade, high_trade} <- compute_trade_value(orders, account, trader),
         {:ok, orders_to_place} <- compute_orders(orders, low_trade, high_trade, trader),
         response <- post_orders(orders_to_place, account, trader) do
      response
    else
      response -> response
    end
  end

  # Get all open orders for the given account and for the given instrument.
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
      poison_error -> handle_poison_error(poison_error)
    end
  end

  # If there is no open order, we get the current market price.
  # We set low_trade and high_trade values to the current price.
  defp compute_trade_value([], account, trader) do
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
      {:ok, format_float(price, trader), format_float(price, trader)}
    else
      poison_error -> handle_poison_error(poison_error)
    end
  end

  # If there are open take_profit orders, we find the lowest and highest price of the orders from them.
  # If there are open orders but no take_profit orders, we wait for the first executed order.
  defp compute_trade_value(orders, _account, %{instrument: instr, options: options} = trader) do
    orders = Enum.filter(orders, fn %{"type" => type} -> type == "TAKE_PROFIT" end)

    if length(orders) > 0 do
      price_divider = :math.pow(10, instr.round_decimal)

      %{"price" => low_trade} = Enum.min_by(orders, fn %{"price" => price} -> String.to_float(price) end)
      %{"price" => high_trade} = Enum.max_by(orders, fn %{"price" => price} -> String.to_float(price) end)

      low_trade = format_float(low_trade, trader) - options.distance_on_take_profit / price_divider
      high_trade = format_float(high_trade, trader) - options.distance_on_take_profit / price_divider

      {:ok, low_trade, high_trade}
    else
      [{:no_event, :waiting_for_first_executed_order, %{}}]
    end
  end

  # Given a list of market_if_touched orders, we compute the list of orders to place.
  # - We add the orders that are missing (not already placed).
  # - [not use now] We remove the orders that are too far from the current price (cleaning).
  #   We don't use this feature for now because we set orders to auto-expire after 24 hours (GFD orders).
  defp compute_orders(orders, low_trade, high_trade, %{instrument: instr, options: options} = trader) do
    price_divider = :math.pow(10, instr.round_decimal)
    order_range = (options.max_order + 1) * options.distance_between_position / price_divider
    high_limit = high_trade + order_range
    low_limit = low_trade - order_range

    {_orders_to_remove, orders_to_keep} =
      orders
      |> Enum.filter(fn %{"type" => type} -> type == "MARKET_IF_TOUCHED" end)
      |> Enum.split_with(fn %{"price" => price} ->
        format_float(price, trader) > high_limit || format_float(price, trader) < low_limit
      end)

    orders_to_keep = Enum.map(orders_to_keep, fn %{"price" => price} -> format_float(price, trader) end)

    orders_to_place =
      1..options.max_order
      |> Enum.map(fn i ->
        [
          format_float(low_trade - i * options.distance_between_position / price_divider, trader),
          format_float(i * options.distance_between_position / price_divider + high_trade, trader)
        ]
      end)
      |> List.flatten()
      |> Enum.filter(fn price ->
        not Enum.any?(orders_to_keep, fn order_price -> order_price == price end)
      end)
      |> Enum.map(fn price ->
        tp_price = format_float_to_string(price + options.distance_on_take_profit / price_divider, trader)
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

    {:ok, orders_to_place}
  end

  defp post_orders([], _account, _trader) do
    [{:no_event, :no_orders_to_place, %{}}]
  end

  defp post_orders(orders, account, trader) do
    orders
    |> Task.async_stream(
      fn order -> post_order(order, account, trader) end,
      timeout: trader.rate_ms,
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    |> Enum.map(fn
      {:ok, response} -> response
      {:exit, {{:ok, _response}, reason}} -> {:error, :task_error, %{reason: reason}}
    end)
  end

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
        {:event, :order_placed, %{request_id: String.to_integer(request_id)}}

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
        [{:error, :wrong_http_code, %{status_code: code}}]

      {:ok, %HTTPoison.Response{} = poison_response} ->
        [{:error, :bad_http_response, Map.from_struct(poison_response)}]

      {:error, poison_error} ->
        [{:error, :poison_error, Map.from_struct(poison_error)}]
    end
  end
end
