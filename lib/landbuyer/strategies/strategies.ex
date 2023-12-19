defmodule Landbuyer.Strategies.Strategies do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @type event() :: {:event, atom(), map()}
  @type no_event() :: {:no_event, atom(), map()}
  @type error() :: {:error, atom(), map()}
  @type events() :: [event() | no_event() | error()]

  @doc "TODO"
  @callback key() :: atom()

  @doc "TODO"
  @callback name() :: String.t()

  @doc "TODO"
  @callback run(Account.t(), Trader.t()) :: events()

  @spec all() :: [atom()]
  def all() do
    [
      Landbuyer.Strategies.Empty,
      Landbuyer.Strategies.LandbuyerOrigin
    ]
  end
end
