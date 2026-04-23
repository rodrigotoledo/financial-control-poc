defmodule Backend.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :amount, :decimal, precision: 18, scale: 2, null: false
      add :idempotency_key, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:account_id])
    create unique_index(:transactions, [:idempotency_key])
  end
end
