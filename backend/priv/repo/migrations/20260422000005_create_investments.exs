defmodule Backend.Repo.Migrations.CreateInvestments do
  use Ecto.Migration

  def change do
    create table(:investments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :fund_id, references(:funds, on_delete: :delete_all), null: false
      add :shares_count, :decimal, precision: 18, scale: 4, null: false
      add :invested_amount, :decimal, precision: 18, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:investments, [:user_id])
    create index(:investments, [:fund_id])
  end
end
