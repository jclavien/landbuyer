defmodule Landbuyer.Schemas.Trader do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Instrument
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Schemas.TraderOptions

  @states [:paused, :active]
  @strategies [Landbuyer.Strategies.Empty]

  @type t() :: %Trader{
          id: integer() | nil,
          state: atom() | nil,
          strategy: atom() | nil,
          rate_ms: integer() | nil,
          instrument: Instrument.t() | nil,
          options: TraderOptions.t() | nil
        }
  schema("traders") do
    field(:state, Ecto.Enum, values: @states)
    field(:strategy, Ecto.Enum, values: Enum.map(@strategies, fn strat -> strat.key() end))
    field(:rate_ms, :integer)
    embeds_one(:instrument, Instrument, on_replace: :update)
    embeds_one(:options, TraderOptions, on_replace: :update)
    belongs_to(:account, Account)

    timestamps(type: :naive_datetime_usec)
  end

  @spec changeset(Trader.t(), map()) :: Ecto.Changeset.t()
  def changeset(trader, params \\ %{}) do
    trader
    |> cast(params, [:state, :strategy, :rate_ms])
    |> validate_required([:state, :strategy, :rate_ms])
    |> validate_inclusion(:state, @states)
    |> validate_inclusion(:strategy, Enum.map(@strategies, fn strat -> strat.key() end))
    |> cast_embed(:instrument, with: &Instrument.changeset/2)
    |> cast_embed(:options, with: &TraderOptions.changeset/2)
  end

  @spec strategies() :: Keyword.t()
  def strategies() do
    Enum.map(@strategies, fn strat -> {strat.name(), strat.key()} end)
  end
end
