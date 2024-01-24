defmodule Landbuyer.Schemas.Event do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.Event
  alias Landbuyer.Schemas.Trader

  @types [:success, :nothing, :error]

  @type t() :: %Event{
          __meta__: Ecto.Schema.Metadata.t() | nil,
          id: integer() | nil,
          type: atom() | nil,
          reason: String.t() | nil,
          message: map() | nil,
          trader_id: integer() | nil,
          trader: Trader.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil
        }
  schema("events") do
    field(:type, Ecto.Enum, values: @types)
    field(:reason, :string)
    field(:message, :map)
    belongs_to(:trader, Trader)

    timestamps(type: :naive_datetime_usec, updated_at: false)
  end

  @spec changeset(Event.t()) :: Ecto.Changeset.t()
  @spec changeset(Event.t(), map()) :: Ecto.Changeset.t()
  def changeset(trader, params \\ %{}) do
    trader
    |> cast(params, [:type, :reason, :message])
    |> validate_required([:type, :reason, :message], message: "Champ requis")
    |> validate_inclusion(:type, @types, message: "Valeur invalide")
  end
end
