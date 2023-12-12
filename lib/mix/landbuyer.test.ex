defmodule Mix.Tasks.Landbuyer.Test do
  @shortdoc "TODO."

  @moduledoc """
  TODO.
  """

  use Mix.Task

  require Logger

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:httpoison)

    data = %{
      hostname: "api-fxpractice.oanda.com",
      # streamingHostname: "stream-fxpractice.oanda.com",
      # port: 443,
      # ssl: true,
      token: "6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c",
      # username: "coeje",
      # accounts: ["101-001-756041-001"],
      activeAccount: "101-001-756041-001"
    }

    request = %HTTPoison.Request{
      method: :get,
      url: "https://#{data.hostname}/v3/accounts/#{data.activeAccount}",
      headers: [{"Authorization", "Bearer #{data.token}"}]
    }

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.request(request),
         {:ok, response} <- Poison.decode(body) do
      IO.inspect(response)
      :ok
    else
      {:error, error} ->
        IO.inspect(error)
        {:error, error}

      error ->
        IO.inspect(error)
        {:error, error}
    end
  end
end

# v3/accounts
# %{"accounts" => [%{"id" => "101-001-756041-001", "tags" => []}]}

# v3/accounts/id
# ? sometimes 307
# %{
#   "account" => %{
#     "marginCloseoutMarginUsed" => "0.0000",
#     "positions" => [
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0.0000",
#         "financing" => "0.0000",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "EUR_USD",
#         "long" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.7896",
#           "resettablePL" => "0.7896",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "0.7896",
#         "resettablePL" => "0.7896",
#         "short" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.0000",
#           "resettablePL" => "0.0000",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       },
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0",
#         "financing" => "0.0493",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "EUR_ZAR",
#         "long" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "-0.0365",
#           "resettablePL" => "-0.0365",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "-0.6455",
#         "resettablePL" => "-0.6455",
#         "short" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "0.0493",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "-0.6090",
#           "resettablePL" => "-0.6090",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       },
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0",
#         "financing" => "0.1429",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "USD_CHF",
#         "long" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "0.1429",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.2544",
#           "resettablePL" => "0.2544",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "1.2544",
#         "resettablePL" => "1.2544",
#         "short" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "1.0000",
#           "resettablePL" => "1.0000",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       },
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0.0000",
#         "financing" => "0.0000",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "GBP_JPY",
#         "long" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.9119",
#           "resettablePL" => "0.9119",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "0.9119",
#         "resettablePL" => "0.9119",
#         "short" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.0000",
#           "resettablePL" => "0.0000",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       },
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0.0000",
#         "financing" => "0.0000",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "AUD_USD",
#         "long" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "-0.0025",
#           "resettablePL" => "-0.0025",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "-0.0025",
#         "resettablePL" => "-0.0025",
#         "short" => %{
#           "dividendAdjustment" => "0.0000",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.0000",
#           "resettablePL" => "0.0000",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       },
#       %{
#         "commission" => "0.0000",
#         "dividendAdjustment" => "0",
#         "financing" => "2.1394",
#         "guaranteedExecutionFees" => "0.0000",
#         "instrument" => "TRY_JPY",
#         "long" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "2.1394",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "4.4195",
#           "resettablePL" => "4.4195",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "pl" => "4.4195",
#         "resettablePL" => "4.4195",
#         "short" => %{
#           "dividendAdjustment" => "0",
#           "financing" => "0.0000",
#           "guaranteedExecutionFees" => "0.0000",
#           "pl" => "0.0000",
#           "resettablePL" => "0.0000",
#           "units" => "0",
#           "unrealizedPL" => "0.0000"
#         },
#         "unrealizedPL" => "0.0000"
#       }
#     ],
#     "openTradeCount" => 0,
#     "id" => "101-001-756041-001",
#     "guaranteedExecutionFees" => "0.0000",
#     "marginRate" => "0.02",
#     "createdTime" => "2018-11-26T15:24:46.334358320Z",
#     "unrealizedPL" => "0.0000",
#     "marginAvailable" => "10009.0590",
#     "trades" => [],
#     "commission" => "0.0000",
#     "resettablePLTime" => "0",
#     "marginCallPercent" => "0.00000",
#     "withdrawalLimit" => "10009.0590",
#     "marginCloseoutUnrealizedPL" => "0.0000",
#     "currency" => "CHF",
#     "createdByUserID" => 756041,
#     "alias" => "Primary V20",
#     "marginCallMarginUsed" => "0.0000",
#     "orders" => [],
#     "marginCloseoutPositionValue" => "0.0000",
#     "pendingOrderCount" => 0,
#     "NAV" => "10009.0590",
#     "dividendAdjustment" => "0",
#     "marginUsed" => "0.0000",
#     "positionValue" => "0.0000",
#     "guaranteedStopLossOrderMode" => "DISABLED",
#     "financing" => "2.3316",
#     "balance" => "10009.0590",
#     "lastTransactionID" => "3402",
#     "marginCloseoutPercent" => "0.00000",
#     "resettablePL" => "6.7274",
#     "marginCloseoutNAV" => "10009.0590",
#     "openPositionCount" => 0,
#     "pl" => "6.7274",
#     "hedgingEnabled" => false
#   },
#   "lastTransactionID" => "3402"
# }
