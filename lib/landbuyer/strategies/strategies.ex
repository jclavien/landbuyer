defmodule Landbuyer.Strategies.Strategies do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @typedoc """
  An event success type happens when the strategy require an action to be taken and the action is successful.
  """
  @type success() :: {:success, atom(), map()}

  @typedoc """
  An event nothing type happens when an the strategy require no actions to be taken but is considered as normal.
  """
  @type nothing() :: {:nothing, atom(), map()}

  @typedoc """
  An event error type happens when the strategy require an action to be taken but the action is not successful.
  """
  @type error() :: {:error, atom(), map()}

  @typedoc """
  An event is either a success, a nothing, or an error.
  """
  @type event() :: success() | nothing() | error()

  @typedoc """
  A list of events that a strategy return. It is a list of either successes, nothings, or errors.
  """
  @type events() :: [event()]

  @doc """
  Get the key of the strategy (used internally and in the database)
  """
  @callback key() :: atom()

  @doc """
  Get the name of the strategy (used in the UI)
  """
  @callback name() :: String.t()

  @doc """
  Run the strategy
  """
  @callback run(Account.t(), Trader.t()) :: events()

  @spec all() :: [atom()]
  def all do
    [
      Landbuyer.Strategies.Empty,
      Landbuyer.Strategies.LandbuyerOrigin
    ]
  end
end
