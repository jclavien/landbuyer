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
  def run(account_opts, trader_opts) do
    with {:ok, orders} <- get_open_orders(account_opts, trader_opts),
         {:ok, low_trade, high_trade} <- compute_trade_value(orders, account_opts, trader_opts),
         {:ok, orders_to_place} <- compute_orders(orders, low_trade, high_trade, trader_opts),
         response <- post_orders(orders_to_place, account_opts, trader_opts) do
      response
    else
      response -> response
    end
  end

  # Get all open orders for the given account and for the given instrument.
  defp get_open_orders(account_opts, trader_opts) do
    baseurl = "https://#{account_opts.hostname}/v3/accounts/#{account_opts.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/orders?state=PENDING&instrument=#{trader_opts.instrument.currency_pair}&count=500",
      headers: [{"Authorization", "Bearer #{account_opts.token}"}],
      options: [timeout: trader_opts.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"orders" => orders}} <- Poison.decode(body) do
      {:ok, orders}
    else
      {:ok, %HTTPoison.Response{status_code: code}} ->
        [{:error, :wrong_http_code, %{"status_code" => code}}]

      {:ok, http_response} ->
        [{:error, :bad_http_response, Map.from_struct(http_response)}]

      {:error, poison_error} ->
        [{:error, :poison_error, Map.from_struct(poison_error)}]
    end
  end

  # If there is no open order, we get the current market price.
  # We set low_trade and high_trade values to the current price.
  defp compute_trade_value([], account_opts, trader_opts) do
    baseurl = "https://#{account_opts.hostname}/v3/accounts/#{account_opts.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/pricing?instruments=#{trader_opts.instrument.currency_pair}",
      headers: [{"Authorization", "Bearer #{account_opts.token}"}],
      options: [timeout: trader_opts.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"prices" => prices}} <- Poison.decode(body) do
      %{"closeoutAsk" => price} = hd(prices)
      {:ok, format_float(price, trader_opts), format_float(price, trader_opts)}
    else
      {:ok, %HTTPoison.Response{status_code: code}} ->
        [{:error, :wrong_http_code, %{"status_code" => code}}]

      {:ok, http_response} ->
        [{:error, :bad_http_response, Map.from_struct(http_response)}]

      {:error, poison_error} ->
        [{:error, :poison_error, Map.from_struct(poison_error)}]
    end
  end

  # If there is open orders, we find the lowest and highest price of the orders from the orders.
  defp compute_trade_value(orders, _account_opts, %{instrument: instr, options: options} = trader_opts) do
    orders = Enum.filter(orders, fn %{"type" => type} -> type == "TAKE_PROFIT" end)

    if length(orders) > 0 do
      price_divider = :math.pow(10, instr.round_decimal)

      %{"price" => low_trade} = Enum.min_by(orders, fn %{"price" => price} -> String.to_float(price) end)
      %{"price" => high_trade} = Enum.max_by(orders, fn %{"price" => price} -> String.to_float(price) end)

      low_trade = format_float(low_trade, trader_opts) - options.distance_on_take_profit / price_divider
      high_trade = format_float(high_trade, trader_opts) - options.distance_on_take_profit / price_divider

      {:ok, low_trade, high_trade}
    else
      [{:no_event, :waiting_for_first_executed_order, %{}}]
    end
  end

  defp compute_orders(orders, low_trade, high_trade, %{instrument: instr, options: options} = trader_opts) do
    price_divider = :math.pow(10, instr.round_decimal)
    order_range = (options.max_order + 1) * options.distance_between_position / price_divider
    high_limit = high_trade + order_range
    low_limit = low_trade - order_range

    # We don't use order to remove for now
    {_orders_to_remove, orders_to_keep} =
      orders
      |> Enum.filter(fn %{"type" => type} -> type == "MARKET_IF_TOUCHED" end)
      |> Enum.split_with(fn %{"price" => price} ->
        format_float(price, trader_opts) > high_limit || format_float(price, trader_opts) < low_limit
      end)

    orders_to_keep = Enum.map(orders_to_keep, fn %{"price" => price} -> format_float(price, trader_opts) end)

    orders_to_place =
      1..options.max_order
      |> Enum.map(fn i ->
        [
          format_float(low_trade - i * options.distance_between_position / price_divider, trader_opts),
          format_float(i * options.distance_between_position / price_divider + high_trade, trader_opts)
        ]
      end)
      |> List.flatten()
      |> Enum.filter(fn price ->
        not Enum.any?(orders_to_keep, fn order_price -> order_price == price end)
      end)
      |> Enum.map(fn price ->
        tp_price = format_float_to_string(price + options.distance_on_take_profit / price_divider, trader_opts)
        price = format_float_to_string(price, trader_opts)

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

  defp post_orders([], _account_opts, _trader_opts) do
    [{:no_event, :no_orders_to_place, %{}}]
  end

  defp post_orders(orders, account_opts, trader_opts) do
    orders
    |> Task.async_stream(
      fn order -> post_order(order, account_opts, trader_opts) end,
      timeout: trader_opts.rate_ms,
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    |> Enum.map(fn
      {:ok, response} -> response
      {:exit, {{:ok, _response}, reason}} -> {:error, :task_error, %{reason: reason}}
    end)
  end

  defp post_order(order, account_opts, trader_opts) do
    request = %HTTPoison.Request{
      method: :post,
      url: "https://#{account_opts.hostname}/v3/accounts/#{account_opts.oanda_id}/orders",
      headers: [
        {"Authorization", "Bearer #{account_opts.token}"},
        {"Content-Type", "application/json"}
      ],
      options: [timeout: trader_opts.rate_ms],
      body: Poison.encode!(%{"order" => order})
    }

    case HTTPoison.request(request) do
      {:ok, %HTTPoison.Response{status_code: 201, headers: headers}} ->
        {_, request_id} = Enum.find(headers, fn {key, _value} -> key == "RequestID" end)
        {:event, :order_placed, %{request_id: String.to_integer(request_id)}}

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, :bad_http_response, %{"status_code" => code}}

      {:error, poison_error} ->
        {:error, :poison_error, Map.from_struct(poison_error)}
    end
  end

  # Helpers

  defp format_float(price, trader_opts) when is_binary(price) do
    price
    |> String.to_float()
    |> Float.round(trader_opts.instrument.round_decimal)
  end

  defp format_float(price, trader_opts) do
    Float.round(price, trader_opts.instrument.round_decimal)
  end

  defp format_float_to_string(price, trader_opts) do
    price
    |> format_float(trader_opts)
    |> Float.to_string()
    |> String.slice(0..(2 + trader_opts.instrument.round_decimal))
  end
end
