defmodule Landbuyer.Strategies.Empty do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @behaviour Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key(), do: :empty

  @spec name() :: String.t()
  def name(), do: "Vide"

  @spec run(Account.t(), Trader.t()) :: :ok
  def run(_account, _trader) do
    :ok
  end
end
