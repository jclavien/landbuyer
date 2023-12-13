defmodule Landbuyer.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create(table(:accounts)) do
      add(:label, :string, null: false)
      add(:oanda_id, :string, null: false)
      add(:hostname, :string, null: false)
      add(:token, :string, null: false)

      timestamps(type: :naive_datetime_usec)
    end

    create(table(:traders)) do
      add(:state, :string, null: false)
      add(:strategy, :string, null: false)
      add(:rate_ms, :integer, null: false)
      add(:instrument, :map, null: false)
      add(:options, :map, null: false)
      add(:account_id, references(:accounts, on_delete: :delete_all), null: false)

      timestamps(type: :naive_datetime_usec)
    end
  end
end
