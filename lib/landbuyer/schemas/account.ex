defmodule Landbuyer.Schemas.Account do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @type t() :: %Account{
          __meta__: Ecto.Schema.Metadata.t() | nil,
          id: integer() | nil,
          label: String.t() | nil,
          oanda_id: String.t() | nil,
          hostname: String.t() | nil,
          token: String.t() | nil,
          traders: [Trader.t()] | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema("accounts") do
    field(:label, :string)
    field(:oanda_id, :string)
    field(:hostname, :string)
    field(:token, :string)
    has_many(:traders, Trader)

    timestamps(type: :naive_datetime_usec)
  end

  @spec changeset(Account.t()) :: Ecto.Changeset.t()
  @spec changeset(Account.t(), map()) :: Ecto.Changeset.t()
  def changeset(account, params \\ %{}) do
    account
    |> cast(params, [:label, :hostname, :token, :oanda_id])
    |> validate_required([:label, :hostname, :token, :oanda_id], message: "Required")
    |> validate_length(:label, max: 255, message: "Dépasse la limite de 255 caractère")
    |> validate_length(:hostname, max: 255, message: "Dépasse la limite de 255 caractère")
    |> validate_length(:token, max: 255, message: "Dépasse la limite de 255 caractère")
    |> validate_length(:oanda_id, max: 25, message: "Dépasse la limite de 25 caractère")
  end
end
