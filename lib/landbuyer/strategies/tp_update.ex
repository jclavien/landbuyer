defmodule Landbuyer.Strategies.TakeProfitUpdate do
  @moduledoc """
  Landbuyer Take Profit Update strategy.

  This strategy is used to update the Take Profit of all the trades that are still open
  on the account. It will update the Take Profit to the current price + the distance on
  the Take Profit option.

  This strategy will also clean all the Market if Touched orders, given an instrument,
  that are still pending on the account.
  """

  @behaviour Landbuyer.Strategies.Strategies

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key, do: :tp_update

  @spec name() :: String.t()
  def name, do: "Take Profit Update"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(account, trader) do
    with {:ok, mit_orders} <- get_mit_orders(account, trader),
         {:ok, trades} <- get_trades(account, trader) do
      trade_events = update_trades(trades, account, trader)
      order_events = delete_orders(mit_orders, account, trader)

      trade_events ++ order_events
    end
  end

  @spec get_mit_orders(Account.t(), Trader.t()) :: {:ok, list()} | Strategies.events()
  defp get_mit_orders(account, trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/orders?state=PENDING&instrument=#{trader.instrument.currency_pair}&count=500",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"orders" => orders}} <- Poison.decode(body) do
      mit_orders = Enum.filter(orders, fn %{"type" => type} -> type == "MARKET_IF_TOUCHED" end)
      {:ok, mit_orders}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec get_trades(Account.t(), Trader.t()) :: {:ok, list()} | Strategies.events()
  defp get_trades(account, trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :get,
      url: "#{baseurl}/trades?state=OPEN&instrument=#{trader.instrument.currency_pair}&count=500",
      headers: [{"Authorization", "Bearer #{account.token}"}],
      options: [timeout: trader.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"trades" => trades}} <- Poison.decode(body) do
      {:ok, trades}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec update_trades(list(), Account.t(), Trader.t()) :: Strategies.events()
  defp update_trades(trades, account, trader) do
    opts = [timeout: trader.rate_ms, on_timeout: :kill_task, zip_input_on_exit: true]

    trades
    |> Task.async_stream(&update_trade(&1, account, trader), opts)
    |> Enum.map(fn
      {:ok, response} -> response
      {:exit, {{:ok, _response}, reason}} -> {:error, :task_error, %{reason: reason}}
    end)
  end

  @spec update_trade(map(), Account.t(), Trader.t()) :: Strategies.event()
  defp update_trade(trade, account, trader) do
    price_divider = :math.pow(10, trader.instrument.round_decimal)
    dist_on_take_profit = trader.options.distance_on_take_profit / price_divider

    trade_tp = trade["takeProfitOrder"]
    price = to_float(trade_tp["price"], trader.instrument.round_decimal)
    new_price = float_to_string(price + dist_on_take_profit, trader.instrument.round_decimal)
    trade_tp = %{trade_tp | "price" => new_price}

    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :put,
      url: "#{baseurl}/trades/#{trade["id"]}/orders",
      headers: [
        {"Authorization", "Bearer #{account.token}"},
        {"Content-Type", "application/json"}
      ],
      options: [timeout: trader.rate_ms],
      body: Poison.encode!(%{"takeProfit" => trade_tp})
    }

    case HTTPoison.request(request) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} ->
        {_, request_id} = Enum.find(headers, fn {key, _value} -> key == "RequestID" end)
        {:success, :trade_updated, %{request_id: String.to_integer(request_id), price: new_price}}

      poison_error ->
        handle_poison_error(poison_error)
    end
  end

  @spec delete_orders(list(), Account.t(), Trader.t()) :: Strategies.events()
  defp delete_orders([], _account, _trader) do
    [{:nothing, :no_orders_to_delete, %{}}]
  end

  defp delete_orders(orders, account, trader) do
    opts = [timeout: trader.rate_ms, on_timeout: :kill_task, zip_input_on_exit: true]

    orders
    |> Task.async_stream(&delete_order(&1, account, trader), opts)
    |> Enum.map(fn
      {:ok, response} -> response
      {:exit, {{:ok, _response}, reason}} -> {:error, :task_error, %{reason: reason}}
    end)
  end

  @spec delete_order(map(), Account.t(), Trader.t()) :: Strategies.event()
  defp delete_order(order, account, trader) do
    baseurl = "https://#{account.hostname}/v3/accounts/#{account.oanda_id}"

    request = %HTTPoison.Request{
      method: :put,
      url: "#{baseurl}/orders/#{order["id"]}/cancel",
      headers: [
        {"Authorization", "Bearer #{account.token}"},
        {"Content-Type", "application/json"}
      ],
      options: [timeout: trader.rate_ms],
      body: Poison.encode!(%{"order" => order})
    }

    case HTTPoison.request(request) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:success, :order_deleted, %{}}

      poison_error ->
        handle_poison_error(poison_error)
    end
  end

  # Helpers

  defp to_float(price, decimal) when is_binary(price) do
    price
    |> String.to_float()
    |> to_float(decimal)
  end

  defp to_float(price, decimal) do
    Float.round(price, decimal)
  end

  defp float_to_string(price, decimal) do
    price
    |> to_float(decimal)
    |> Float.to_string()
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
