defmodule Landbuyer.Strategies.LandbuyerOrigin do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @behaviour Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key(), do: :landbuyer_origin

  @spec name() :: String.t()
  def name(), do: "Landbuyer Origin"

  @spec run(Account.t(), Trader.t()) :: {:event, atom(), map()} | {:no_event, atom(), map()} | {:error, atom(), map()}
  def run(account_opts, trader_opts) do
    with {:ok, account} <- get_account(account_opts, trader_opts),
         {:ok} <- have_pending_order(account),
         {:ok, orders_price} <- compute_orders(trader_opts),
         {:ok, orders_struct} <- create_orders(orders_price, trader_opts),
         {return_status, message, data} <- post_orders(orders_struct, account_opts, trader_opts) do
      {return_status, message, data}
    else
      response -> response
    end
  end

  defp get_account(account_opts, trader_opts) do
    request = %HTTPoison.Request{
      method: :get,
      url: "https://#{account_opts.hostname}/v3/accounts/#{account_opts.oanda_id}",
      headers: [{"Authorization", "Bearer #{account_opts.token}"}],
      options: [timeout: trader_opts.rate_ms]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, %{"account" => account}} <- Poison.decode(body) do
      {:ok, account}
    else
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        # Register only usefull info for "body"
        {:error, :wrong_http_code, %{"status_code" => code, "body" => body}}

      {:ok, http_response} ->
        # Register only usefull info for "http_response"
        {:error, :bad_http_response, Map.from_struct(http_response)}

      {:error, poison_error} ->
        # Register only usefull info for "poison_error"
        {:error, :poison_error, Map.from_struct(poison_error)}
    end
  end

  defp have_pending_order(account_opts) do
    if account_opts["pendingOrderCount"] > 0,
      do: {:ok},
      else: {:no_event, :no_pending_orders, %{}}
  end

  defp compute_orders(_trader_opts) do
    # get trade orders
    # sort trade orders
    _trade_orders = []

    # get limit orders
    # sort limit orders
    _limit_orders = []

    # compute high and low prices
    _high_trade_value = 0
    _low_trade_value = 0

    # compute order to be placer
    orders_to_place = if Enum.random(1..2) == 1, do: [], else: [5.0]
    # take_profit_to_place = [] (see what's the use)
    # - on rempli un tableau avec les niveau de prix des ordres que l'on devrait ouvrir
    # - idem pour les ordres inférieurs
    # - sort orders

    {:ok, orders_to_place}
  end

  defp create_orders([], _trader_opts) do
    {:no_event, :no_orders_to_place, %{}}
  end

  defp create_orders(orders_to_place, trader_opts) do
    orders =
      Enum.map(orders_to_place, fn order ->
        %{
          type: "MARKET_IF_TOUCHED",
          instrument: trader_opts.instrument.currency_pair,
          units: trader_opts.options.position_amount,
          price: Integer.to_string(order),
          timeInForce: "GTC",
          takeProfitOnFill: %{
            timeInForce: "GTC",
            # TODO: round to given precision
            price: Integer.to_string(order + trader_opts.options.distance_on_take_profit)
          }
        }
      end)

    {:ok, orders}
  end

  defp post_orders(orders, account_opts, trader_opts) do
    # TODO: use Task.async_stream
    %{ok: valid_requests, errors: failed_requests} =
      orders
      |> Enum.map(fn order -> do_post_orders(order, account_opts, trader_opts) end)
      |> Enum.group_by(
        fn tuple -> elem(tuple, 0) end,
        fn x -> x end
      )

    data = %{
      valid_requests: valid_requests,
      valid_requests_count: length(valid_requests),
      failed_requests: failed_requests,
      failed_requests_count: length(failed_requests)
    }

    cond do
      failed_requests == [] -> {:event, :all_orders_placed, data}
      valid_requests == [] -> {:error, :all_orders_failed, data}
      true -> {:error, :some_orders_placed, data}
    end
  end

  defp do_post_orders(order, account_opts, trader_opts) do
    request = %HTTPoison.Request{
      method: :post,
      url: "https://#{account_opts.hostname}/v3/accounts/#{account_opts.oanda_id}/orders",
      headers: [{"Authorization", "Bearer #{account_opts.token}"}],
      options: [timeout: trader_opts.rate_ms],
      body: %{"order" => order}
    }

    case HTTPoison.request(request) do
      {:ok, %HTTPoison.Response{status_code: 201, headers: [_location, request_id]}} ->
        {:ok, request_id}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        # Register only usefull info for "body"
        {:error, :order_specification_invalid, %{"status_code" => 400, "body" => body}}

      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        # Register only usefull info for "body"
        {:error, :order_or_account_unknown, %{"status_code" => 404, "body" => body}}

      {:error, poison_error} ->
        # Register only usefull info for "poison_error"
        {:error, :poison_error, Map.from_struct(poison_error)}
    end
  end
end
