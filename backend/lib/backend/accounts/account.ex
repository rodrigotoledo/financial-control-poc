defmodule Backend.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:balance, :decimal)
    field(:version, :integer, default: 0)

    belongs_to(:user, Backend.Accounts.User)
    has_many(:transactions, Backend.Transactions.Transaction)

    timestamps(type: :utc_datetime)
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:balance, :version, :user_id])
    |> validate_required([:balance, :user_id])
  end
end
