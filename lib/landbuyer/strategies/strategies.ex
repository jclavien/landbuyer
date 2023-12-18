defmodule Landbuyer.Strategies.Strategies do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @doc "TODO"
  @callback key() :: atom()

  @doc "TODO"
  @callback name() :: String.t()

  @doc "TODO"
  @callback run(Account.t(), Trader.t()) ::
              [{:event, atom(), map()} | {:no_event, atom(), map()} | {:error, atom(), map()}]

  @spec all() :: [atom()]
  def all() do
    [
      Landbuyer.Strategies.Empty,
      Landbuyer.Strategies.LandbuyerOrigin
    ]
  end
end
