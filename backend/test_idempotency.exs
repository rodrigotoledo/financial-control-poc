#!/usr/bin/env elixir
# Script para testar idempotência: mesma requisição de saque 2x com mesma chave deve falhar na 2ª

Mix.start()
Mix.ensure_application!(:httpc)

{:ok, _} = Application.ensure_all_started(:backend)

alias Backend.Repo
alias Backend.Accounts
alias Backend.Accounts.Account
alias Backend.Transactions

# Cleanup
Repo.delete_all(Account)
Repo.delete_all(Accounts.User)

# Create user and account
user =
  %Accounts.User{}
  |> Accounts.User.changeset(%{email: "test@example.com", password: "test123"})
  |> Repo.insert!()

account =
  %Account{}
  |> Account.changeset(%{user_id: user.id, balance: Decimal.new("100.00")})
  |> Repo.insert!()

idempotency_key = "test-key-#{System.unique_integer()}"

# First request: should succeed
{:ok, tx1} =
  Transactions.process_transaction(account.id, "withdraw", Decimal.new("50.00"), idempotency_key)

IO.puts("✓ First request succeeded: #{inspect(tx1)}")

# Second request with SAME key: should fail with :duplicate_request
{:error, reason} =
  Transactions.process_transaction(account.id, "withdraw", Decimal.new("50.00"), idempotency_key)

IO.puts("✓ Second request (same key) failed with: #{inspect(reason)}")

# Verify balance didn't get deducted twice
account = Repo.get!(Account, account.id)
IO.puts("✓ Final balance: #{account.balance} (should be 50.00)")

if account.balance == Decimal.new("50.00") do
  IO.puts("✓ Idempotency test PASSED!")
else
  IO.puts("✗ Idempotency test FAILED!")
end
