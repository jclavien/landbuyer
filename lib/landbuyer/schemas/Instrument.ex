defmodule Landbuyer.Schemas.Instrument do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.Instrument

  @type t() :: %Instrument{
          id: integer() | nil,
          currency_pair: String.t() | nil,
          round_decimal: integer() | nil
        }
  embedded_schema do
    field(:currency_pair, :string)
    field(:round_decimal, :integer)
  end

  @spec changeset(Instrument.t(), map()) :: Ecto.Changeset.t()
  def changeset(instrument, params \\ %{}) do
    instrument
    |> cast(params, [:currency_pair, :round_decimal])
    |> validate_required([:currency_pair, :round_decimal], message: "Champ requis")
    |> validate_format(:currency_pair, ~r/^[A-Z]{3}_[A-Z]{3}$/, message: "Format invalide")
    |> validate_inclusion(:round_decimal, 1..10, message: "Valeur invalide")
  end
end
