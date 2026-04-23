defmodule Backend.Funds.Investment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "investments" do
    field(:shares_count, :decimal)
    field(:invested_amount, :decimal)

    belongs_to(:user, Backend.Accounts.User)
    belongs_to(:fund, Backend.Funds.Fund)

    timestamps(type: :utc_datetime)
  end

  def changeset(investment, attrs) do
    investment
    |> cast(attrs, [:shares_count, :invested_amount, :user_id, :fund_id])
    |> validate_required([:shares_count, :invested_amount, :user_id, :fund_id])
    |> validate_number(:shares_count, greater_than: Decimal.new(0))
    |> validate_number(:invested_amount, greater_than: Decimal.new(0))
  end
end
