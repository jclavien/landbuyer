defmodule Landbuyer.Repo.Migrations.CreateEvent do
  use Ecto.Migration

  def change do
    create(table(:events)) do
      add(:type, :string, null: false)
      add(:reason, :string, null: false)
      add(:message, :map, null: false)
      add(:trader_id, references(:traders, on_delete: :delete_all), null: false)

      timestamps(type: :naive_datetime_usec, updated_at: false)
    end
  end
end
