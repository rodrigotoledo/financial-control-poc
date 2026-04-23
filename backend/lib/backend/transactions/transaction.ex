defmodule Backend.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field(:type, :string)
    field(:amount, :decimal)
    field(:idempotency_key, :string)

    belongs_to(:account, Backend.Accounts.Account)

    timestamps(type: :utc_datetime)
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:type, :amount, :idempotency_key, :account_id])
    |> validate_required([:type, :amount, :idempotency_key, :account_id])
    |> validate_inclusion(:type, ["deposit", "withdraw", "investment"])
    |> validate_number(:amount, greater_than: Decimal.new(0))
    |> unique_constraint(:idempotency_key)
  end
end
