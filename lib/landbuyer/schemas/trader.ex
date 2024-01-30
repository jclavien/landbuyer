defmodule Landbuyer.Schemas.Trader do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Event
  alias Landbuyer.Schemas.Instrument
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Schemas.TraderOptions

  @states [:paused, :active]
  @strategies [
    Landbuyer.Strategies.Empty,
    Landbuyer.Strategies.LandbuyerOrigin,
    Landbuyer.Strategies.MitCleaner
  ]

  @type t() :: %Trader{
          __meta__: Ecto.Schema.Metadata.t() | nil,
          id: integer() | nil,
          state: atom() | nil,
          strategy: atom() | nil,
          rate_ms: integer() | nil,
          instrument: Instrument.t() | nil,
          options: TraderOptions.t() | nil,
          account_id: integer() | nil,
          account: Account.t() | Ecto.Association.NotLoaded.t() | nil,
          events: [Event.t()] | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema("traders") do
    field(:state, Ecto.Enum, values: @states)
    field(:strategy, Ecto.Enum, values: Enum.map(@strategies, fn strat -> strat.key() end))
    field(:rate_ms, :integer)
    embeds_one(:instrument, Instrument, on_replace: :update)
    embeds_one(:options, TraderOptions, on_replace: :update)
    belongs_to(:account, Account)
    has_many(:events, Event)

    timestamps(type: :naive_datetime_usec)
  end

  @spec changeset(Trader.t()) :: Ecto.Changeset.t()
  @spec changeset(Trader.t(), map()) :: Ecto.Changeset.t()
  def changeset(trader, params \\ %{}) do
    trader
    |> cast(params, [:state, :strategy, :rate_ms])
    |> validate_required([:state, :strategy, :rate_ms], message: "Champ requis")
    |> validate_inclusion(:state, @states, message: "Valeur invalide")
    |> validate_inclusion(:strategy, Enum.map(@strategies, fn strat -> strat.key() end), message: "Valeur invalide")
    |> validate_number(:rate_ms, greater_than_or_equal_to: 200, message: "Valeur invalide (> 200)")
    |> cast_embed(:instrument, with: &Instrument.changeset/2)
    |> cast_embed(:options, with: &TraderOptions.changeset/2)
  end

  @spec strategies() :: Keyword.t()
  def strategies do
    Enum.map(@strategies, fn strat -> {strat.name(), strat.key()} end)
  end

  @spec strategy_name(atom()) :: String.t()
  def strategy_name(strategy) do
    Enum.find(@strategies, fn strat -> strat.key() == strategy end).name()
  end
end
