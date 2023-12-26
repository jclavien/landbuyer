defmodule Landbuyer.Strategies.Empty do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @behaviour Strategies

  @spec key() :: atom()
  def key(), do: :empty

  @spec name() :: String.t()
  def name(), do: "Vide"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(_account, _trader) do
    [{:nothing, :empty_strategy, %{}}]
  end
end
