defmodule Landbuyer.AccountSnapshots.AccountSnapshot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:inserted_at, :nav]}
  schema "account_snapshots" do
    field :nav, :decimal
    field :account_id, :integer

    timestamps()
  end

  @doc false
  def changeset(account_snapshot, attrs) do
    account_snapshot
    |> cast(attrs, [:account_id, :nav])
    |> validate_required([:account_id, :nav])
  end
end
