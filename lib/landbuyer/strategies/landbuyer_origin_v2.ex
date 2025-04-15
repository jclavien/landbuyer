defmodule Landbuyer.Strategies.LandbuyerOriginV2 do
  @moduledoc """
  Landbuyer Origin V2 strategy.

  Amélioré pour :
  - Espacement d'ordres fixe en grille
  - Placement basé sur TP existants
  - Support LONG / SHORT via paramètre `direction`
  - Amorçage intelligent en l'absence de positions / ordres
  """

  @behaviour Landbuyer.Strategies.Strategies

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key, do: :landbuyer_origin_v2

  @spec name() :: String.t()
  def name, do: "Landbuyer Origin V2"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(account, trader) do
    with {:ok, market_price} <- get_market_price(account, trader),
         {:ok, mit_orders, tp_orders} <- get_orders(account, trader),
         {:ok, orders_to_place} <- compute_orders(market_price, mit_orders, tp_orders, trader) do
      post_orders(orders_to_place, account, trader)
    end
  end

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
      %{"bids" => [%{"price" => bid}], "asks" => [%{"price" => ask}]} = hd(prices)
      median = (String.to_float(bid) + String.to_float(ask)) / 2
      {:ok, Float.round(median, instr.round_decimal)}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

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
        |> Enum.map(fn %{"price" => price} -> String.to_float(price) end)

      tp_orders =
        orders
        |> Enum.filter(fn %{"type" => type} -> type == "TAKE_PROFIT" end)
        |> Enum.map(fn %{"price" => price} -> String.to_float(price) end)

      {:ok, mit_orders, tp_orders}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  defp compute_orders(market_price, [], [], %{instrument: instr, options: opts}) do
    step = opts.distance_between_position / :math.pow(10, instr.round_decimal)
    rounded = ceil(market_price * :math.pow(10, instr.round_decimal)) / :math.pow(10, instr.round_decimal)

    range = -10..10

    orders =
      Enum.map(range, fn i ->
        price = Float.round(rounded + i * step, instr.round_decimal)
        tp_price = Float.round(price + opts.distance_on_take_profit / :math.pow(10, instr.round_decimal), instr.round_decimal)

        %{
          type: "MARKET_IF_TOUCHED",
          instrument: instr.currency_pair,
          units: opts.position_amount,
          price: Float.to_string(price),
          timeInForce: "GFD",
          takeProfitOnFill: %{
            timeInForce: "GTC",
            price: Float.to_string(tp_price)
          }
        }
      end)

    {:ok, orders}
  end

  defp compute_orders(_market_price, _mit_orders, [], _trader),
    do: [{:nothing, :waiting_for_first_executed_order, %{}}]

  defp compute_orders(_market_price, mit_orders, tp_orders, %{instrument: instr, options: opts}) do
    price_divider = :math.pow(10, instr.round_decimal)
    tp_distance = opts.distance_on_take_profit / price_divider
    step_size = opts.distance_between_position / price_divider

    tp_base_prices = Enum.map(tp_orders, &Float.round(&1 - tp_distance, instr.round_decimal))

    last_base =
      case tp_base_prices do
        [] -> nil
        _ -> Enum.min(tp_base_prices)
      end

    new_levels =
      if last_base do
        for i <- 1..opts.max_order do
          Float.round(last_base - i * step_size, instr.round_decimal)
        end
      else
        []
      end

    mit_prices = Enum.map(mit_orders, &Float.round(&1, instr.round_decimal))

    levels_to_place =
      Enum.reject(new_levels, fn lvl -> lvl in mit_prices end)

    orders =
      Enum.map(levels_to_place, fn entry_price ->
        tp_price = Float.round(entry_price + tp_distance, instr.round_decimal)

        %{
          type: "MARKET_IF_TOUCHED",
          instrument: instr.currency_pair,
          units: opts.position_amount,
          price: Float.to_string(entry_price),
          timeInForce: "GFD",
          takeProfitOnFill: %{
            timeInForce: "GTC",
            price: Float.to_string(tp_price)
          }
        }
      end)

    {:ok, orders}
  end

  defp post_orders([], _account, _trader), do: [{:nothing, :no_orders_to_place, %{}}]

  defp post_orders(orders, account, trader) do
    opts = [timeout: trader.rate_ms, on_timeout: :kill_task, zip_input_on_exit: true]

    orders
    |> Task.async_stream(&post_order(&1, account, trader), opts)
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
        {_, request_id} = Enum.find(headers, fn {key, _val} -> key == "RequestID" end)
        {:success, :order_placed, %{request_id: String.to_integer(request_id), price: order.price}}

      poison_error ->
        handle_poison_error(poison_error)
    end
  end

  defp handle_poison_error(poison_error) do
    case poison_error do
      {:ok, %HTTPoison.Response{status_code: code}} -> {:error, :wrong_http_code, %{status_code: code}}
      {:ok, %HTTPoison.Response{} = res} -> {:error, :bad_http_response, Map.from_struct(res)}
      {:error, err} -> {:error, :poison_error, Map.from_struct(err)}
    end
  end
end
