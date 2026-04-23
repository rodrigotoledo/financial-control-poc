defmodule Backend.Repo.Migrations.CreateFunds do
  use Ecto.Migration

  def change do
    create table(:funds) do
      add :name, :string, null: false
      add :current_share_price, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:funds, [:name])
  end
end
