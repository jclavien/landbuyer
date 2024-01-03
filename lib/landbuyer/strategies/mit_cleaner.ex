defmodule Landbuyer.Strategies.MitCleaner do
  @moduledoc """
  Landbuyer M. if T. cleaner strategy.

  TODO.
  """

  @behaviour Landbuyer.Strategies.Strategies

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key, do: :mit_cleaner

  @spec name() :: String.t()
  def name, do: "M. if T. Cleaner"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(account, trader) do
    with {:ok, mit_orders} <- get_mit_orders(account, trader) do
      delete_orders(mit_orders, account, trader)
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
