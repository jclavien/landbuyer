defmodule Landbuyer.Strategies.LandbuyerOriginV2 do
  IO.puts(">>> LandbuyerOriginV2 LOADED")

  @moduledoc """
  Landbuyer Origin V2 strategy.

  Amélioré pour :
  - Espacement d'ordres fixe en grille
  - Placement basé sur TP existants
  - Support LONG / SHORT via paramètre `direction`
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

  @spec get_market_price(Account.t(), Trader.t()) :: {:ok, float()} | Strategies.events()
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
      mp = to_float(market_price, instr.round_decimal)
      IO.inspect(mp, label: ">>> market_price")
      {:ok, mp}
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
        |> Enum.map(fn %{"price" => price} -> to_float(price, instr.round_decimal) end)

      tp_orders =
        orders
        |> Enum.filter(fn %{"type" => type} -> type == "TAKE_PROFIT" end)
        |> Enum.map(fn %{"price" => price} -> to_float(price, instr.round_decimal) end)

      IO.inspect(mit_orders, label: ">>> mit_orders")
      IO.inspect(tp_orders, label: ">>> tp_orders")

      {:ok, mit_orders, tp_orders}
    else
      poison_error -> [handle_poison_error(poison_error)]
    end
  end

  @spec compute_orders(float(), list(), list(), Trader.t()) :: {:ok, list()} | Strategies.events()
  defp compute_orders(_market_price, _mit_orders, [], _trader), do:
    [{:nothing, :waiting_for_first_executed_order, %{}}]

  defp compute_orders(_market_price, _mit_orders, tp_orders, %{
         instrument: instr,
         options: options
       }) do
    price_divider = :math.pow(10, instr.round_decimal)
    tp_distance = Decimal.from_float(options.distance_on_take_profit / price_divider)
    step_size = Decimal.from_float(options.distance_between_position / price_divider)
    decimal_places = instr.round_decimal

    direction = Map.get(options, :direction, "L")
    is_long = direction == "L"

    tp_prices = Enum.map(tp_orders, &Decimal.from_float/1)

    extreme_tp =
      case is_long do
        true -> Enum.min(tp_prices)
        false -> Enum.max(tp_prices)
      end

    base_entry =
      case is_long do
        true -> Decimal.sub(extreme_tp, tp_distance)
        false -> Decimal.add(extreme_tp, tp_distance)
      end

    new_levels =
      for i <- 1..options.max_order do
        offset = Decimal.mult(step_size, Decimal.new(i))
        case is_long do
          true -> Decimal.sub(base_entry, offset)
          false -> Decimal.add(base_entry, offset)
        end
      end

    IO.inspect(new_levels, label: ">>> new_levels")

    existing_base_entries =
      Enum.map(tp_prices, fn tp ->
        case is_long do
          true -> Decimal.sub(tp, tp_distance)
          false -> Decimal.add(tp, tp_distance)
        end
      end)

    levels_to_place =
      Enum.reject(new_levels, fn lvl ->
        Enum.any?(existing_base_entries, fn existing ->
          Decimal.equal?(Decimal.round(existing, decimal_places), Decimal.round(lvl, decimal_places))
        end)
      end)

    IO.inspect(levels_to_place, label: ">>> levels_to_place")

    orders_to_place =
      Enum.map(levels_to_place, fn entry_price ->
        tp_price =
          case is_long do
            true -> Decimal.add(entry_price, tp_distance)
            false -> Decimal.sub(entry_price, tp_distance)
          end

        %{
          type: "MARKET_IF_TOUCHED",
          instrument: instr.currency_pair,
          units: (is_long && options.position_amount) || -options.position_amount,
          price: Decimal.round(entry_price, decimal_places) |> Decimal.to_string(),
          timeInForce: "GFD",
          takeProfitOnFill: %{
            timeInForce: "GTC",
            price: Decimal.round(tp_price, decimal_places) |> Decimal.to_string()
          }
        }
      end)

    IO.inspect(orders_to_place, label: ">>> orders_to_place")

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
    IO.inspect(order, label: ">>> posting_order")

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
        IO.inspect(poison_error, label: ">>> poison_error")
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
