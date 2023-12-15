defmodule Landbuyer.Strategies.Strategies do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @doc "TODO"
  @callback key() :: atom()

  @doc "TODO"
  @callback name() :: String.t()

  @doc "TODO"
  @callback run(Account.t(), Trader.t()) :: :ok

  @spec all() :: [atom()]
  def all() do
    [
      Landbuyer.Strategies.Empty
    ]
  end
end
