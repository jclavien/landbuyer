defmodule Landbuyer.Workers.State do
  @moduledoc false

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Workers.State

  @type t :: %State{
          name: integer(),
          account: Account.t(),
          trader: Trader.t(),
          data: map()
        }
  defstruct name: nil, account: nil, trader: nil, data: nil
end
