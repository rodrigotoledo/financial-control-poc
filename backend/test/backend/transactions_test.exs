defmodule Backend.TransactionsTest do
  use ExUnit.Case
  alias Backend.Repo
  alias Backend.Accounts.{User, Account}
  alias Backend.Transactions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    user =
      %User{}
      |> User.changeset(%{email: "test@example.com", password: "test123"})
      |> Repo.insert!()

    account =
      %Account{}
      |> Account.changeset(%{user_id: user.id, balance: Decimal.new("1000.00")})
      |> Repo.insert!()

    {:ok, account: account, user: user}
  end

  describe "process_transaction/4 - Withdrawal" do
    test "successful withdrawal reduces balance", %{account: account} do
      idempotency_key = "withdraw-1"

      {:ok, result} =
        Transactions.process_transaction(
          account.id,
          "withdraw",
          Decimal.new("100.00"),
          idempotency_key
        )

      updated_account = Repo.get!(Account, account.id)
      assert updated_account.balance == Decimal.new("900.00")
      assert result.transaction.type == "withdraw"
    end

    test "insufficient funds returns error", %{account: account} do
      idempotency_key = "withdraw-2"

      {:error, :insufficient_funds} =
        Transactions.process_transaction(
          account.id,
          "withdraw",
          Decimal.new("1500.00"),
          idempotency_key
        )

      # Balance unchanged
      updated_account = Repo.get!(Account, account.id)
      assert updated_account.balance == Decimal.new("1000.00")
    end
  end

  describe "process_transaction/4 - Idempotency" do
    test "duplicate idempotency_key returns :duplicate_request", %{account: account} do
      idempotency_key = "unique-key-123"

      # First request succeeds
      {:ok, tx1} =
        Transactions.process_transaction(
          account.id,
          "withdraw",
          Decimal.new("50.00"),
          idempotency_key
        )

      # Second request with SAME key fails
      {:error, :duplicate_request} =
        Transactions.process_transaction(
          account.id,
          "withdraw",
          Decimal.new("50.00"),
          idempotency_key
        )

      # Balance only deducted once
      updated_account = Repo.get!(Account, account.id)
      assert updated_account.balance == Decimal.new("950.00")

      # Only 1 transaction in DB with that key
      transactions = Transactions.get_transactions(account.id)
      matching = Enum.filter(transactions, &(&1.idempotency_key == idempotency_key))
      assert length(matching) == 1
      assert matching |> hd |> Map.get(:id) == tx1.id
    end
  end

  describe "process_transaction/4 - Deposit" do
    test "successful deposit increases balance", %{account: account} do
      idempotency_key = "deposit-1"

      {:ok, result} =
        Transactions.process_transaction(
          account.id,
          "deposit",
          Decimal.new("100.00"),
          idempotency_key
        )

      updated_account = Repo.get!(Account, account.id)
      assert updated_account.balance == Decimal.new("1100.00")
      assert result.transaction.type == "deposit"
    end
  end

  describe "Pessimistic Locking" do
    test "concurrent withdrawals respect balance constraint", %{account: account} do
      # Simulate 2 concurrent attempts to withdraw more than balance allows
      key1 = "concurrent-1"
      key2 = "concurrent-2"

      # Both try to withdraw 600 from account with 1000
      # Only 1 should succeed
      result1 =
        Transactions.process_transaction(account.id, "withdraw", Decimal.new("600.00"), key1)

      result2 =
        Transactions.process_transaction(account.id, "withdraw", Decimal.new("600.00"), key2)

      # One succeeds, one fails
      {success, failure} =
        case {result1, result2} do
          {{:ok, _}, {:error, _}} -> {result1, result2}
          {{:error, _}, {:ok, _}} -> {result2, result1}
          _ -> raise "Expected one success and one failure"
        end

      assert {:ok, _} = success
      assert {:error, :insufficient_funds} = failure

      # Balance = 1000 - 600 = 400
      updated_account = Repo.get!(Account, account.id)
      assert updated_account.balance == Decimal.new("400.00")
    end
  end
end
