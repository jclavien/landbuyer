defmodule Landbuyer.Strategies.Empty do
  @moduledoc """
  Empty strategy.

  This strategy does nothing and may be used as a template for new strategies or as a test strategy
  for gen_server and supervisor behaviours.
  """

  @behaviour Landbuyer.Strategies.Strategies

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Strategies.Strategies

  @spec key() :: atom()
  def key, do: :empty

  @spec name() :: String.t()
  def name, do: "Vide"

  @spec run(Account.t(), Trader.t()) :: Strategies.events()
  def run(_account, _trader) do
    [{:nothing, :empty_strategy, %{}}]
  end
end
