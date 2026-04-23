defmodule Backend.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :balance, :decimal, precision: 18, scale: 2, default: "0.00"
      add :version, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:accounts, [:user_id])
  end
end
