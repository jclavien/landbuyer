defmodule Landbuyer.Repo.Migrations.CreateAccountSnapshots do
  use Ecto.Migration

  def change do
    create table(:account_snapshots) do
      add :account_id, :integer
      add :nav, :decimal

      timestamps()
    end
  end
end
