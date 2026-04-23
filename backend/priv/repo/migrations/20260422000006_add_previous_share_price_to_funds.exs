defmodule Backend.Repo.Migrations.AddPreviousSharePriceToFunds do
  use Ecto.Migration

  def change do
    alter table(:funds) do
      add :previous_share_price, :decimal, precision: 18, scale: 4
    end
  end
end
