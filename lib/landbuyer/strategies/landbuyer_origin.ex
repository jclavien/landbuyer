defmodule Landbuyer.Strategies.LandbuyerOrigin do
  @moduledoc """
  Landbuyer Origin strategy.
  """

  @behaviour Landbuyer.Strategies.Strategies

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key, do: :landbuyer_origin

  @spec name() :: String.t()
  def name, do: "Landbuyer Origin"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(account, trader) do
    with {:ok, market_price} <- get_market_price(account, trader),
         {:ok, mit_orders, tp_orders} <- get_orders(account, trader),
         {:ok, orders_to_place} <- compute_orders(market_price, mit_orders, tp_orders, trader) do
      post_orders(orders_to_place, account, trader)
    end
  end

  @spec get_market_price(Account.t(), Trader.t()) :: {:ok, Decimal.t()} | Strategies.events()
  defp get_market_price(account, %{instrument: instr} = trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/pricing?instruments=#{instr.currency_pair}",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"prices" => prices}} <- Poison.decode(body) do
      %{"closeoutAsk" => market_price} = hd(prices)
      {:ok, Decimal.new(market_price)}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec get_orders(Account.t(), Trader.t()) :: {:ok, list(), list()} | Strategies.events()
  defp get_orders(account, %{instrument: instr} = trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/orders?state=PENDING&instrument=#{instr.currency_pair}&count=500",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"orders" => orders}} <- Poison.decode(body) do
      mit_orders =
        orders
        |> Enum.filter(fn %{"type" => type} -> type == "MARKET_IF_TOUCHED" end)
        |> Enum.map(fn %{"price" => price} -> Decimal.new(price) end)

      tp_orders =
        orders
        |> Enum.filter(fn %{"type" => type} -> type == "TAKE_PROFIT" end)
        |> Enum.map(fn %{"price" => price} -> Decimal.new(price) end)

      {:ok, mit_orders, tp_orders}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec compute_orders(Decimal.t(), list(), list(), Trader.t()) :: {:ok, list()} | Strategies.events()
  defp compute_orders(_market_price, mit_orders, [], _trader) when mit_orders != [] do
    [{:nothing, :waiting_for_first_executed_order, %{}}]
  end

  defp compute_orders(market_price, mit_orders, tp_orders, %{instrument: instr, options: options}) do
    price_divider = Decimal.from_float(:math.pow(10, instr.round_decimal))
    dist_on_take_profit = Decimal.div(options.distance_on_take_profit, price_divider)
    step_size = Decimal.div(options.distance_between_position, price_divider)
    order_range = Decimal.mult(Decimal.add(options.max_order, 1), step_size)
    comparison_range = Decimal.div(Decimal.from_float(0.5), price_divider)
    high_limit = Decimal.add(market_price, order_range)
    low_limit = Decimal.sub(market_price, order_range)

    mit_to_reject =
      Enum.reject(mit_orders, fn price -> Decimal.gt?(price, high_limit) or Decimal.lt?(price, low_limit) end)

    tp_to_reject =
      Enum.reject(tp_orders, fn price ->
        price = Decimal.sub(price, dist_on_take_profit)
        Decimal.gt?(price, high_limit) or Decimal.lt?(price, low_limit)
      end)

    orders_to_place =
      1..options.max_order
      |> Enum.flat_map(fn i ->
        step = Decimal.mult(i, step_size)
        [Decimal.sub(market_price, step), Decimal.add(market_price, step)]
      end)
      |> Enum.reject(fn price ->
        Enum.any?(mit_to_reject, fn x ->
          Decimal.gt?(Decimal.add(x, comparison_range), price) and
            Decimal.lt?(Decimal.sub(x, comparison_range), price)
        end)
      end)
      |> Enum.reject(fn price ->
        Enum.any?(tp_to_reject, fn x ->
          x = Decimal.sub(x, dist_on_take_profit)

          Decimal.gt?(Decimal.add(x, comparison_range), price) and
            Decimal.lt?(Decimal.sub(x, comparison_range), price)
        end)
      end)
      |> Enum.map(fn price ->
        tp_price =
          price |> Decimal.add(dist_on_take_profit) |> Decimal.round(instr.round_decimal) |> Decimal.to_string()

        price = price |> Decimal.round(instr.round_decimal) |> Decimal.to_string()

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
        {:success, :order_placed, %{request_id: String.to_integer(request_id), price: order.price}}

      poison_error ->
        handle_poison_error(poison_error)
    end
  end

  # Helpers

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
