defmodule Backend.Funds.Fund do
  use Ecto.Schema
  import Ecto.Changeset

  schema "funds" do
    field(:name, :string)
    field(:current_share_price, :decimal)
    field(:previous_share_price, :decimal)

    has_many(:investments, Backend.Funds.Investment)

    timestamps(type: :utc_datetime)
  end

  def changeset(fund, attrs) do
    fund
    |> cast(attrs, [:name, :current_share_price, :previous_share_price])
    |> validate_required([:name, :current_share_price])
    |> unique_constraint(:name)
  end
end
