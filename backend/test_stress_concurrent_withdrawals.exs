#!/usr/bin/env elixir
# Stress Test: 10 Saques Simultâneos em Conta com Saldo para 1
#
# OBJETIVO:
#   Testar pessimistic locking (FOR UPDATE) garantindo que apenas 1 saque
#   de $600 passa em conta com $1000. As outras 9 devem falhar com
#   :insufficient_funds (prova de que a conta foi travada corretamente).
#
# COMO RODAR:
#   mix run test_stress_concurrent_withdrawals.exs
#
# RESULTADO ESPERADO:
#   ✓ 1 transação bem-sucedida
#   ✓ 9 transações com erro :insufficient_funds
#   ✓ Saldo final = $400 (apenas 1 saque de $600 passou)

Mix.start()
Mix.ensure_application!(:backend)

alias Backend.Repo
alias Backend.Accounts.{User, Account}
alias Backend.Transactions

# Cleanup
Repo.delete_all(Account)
Repo.delete_all(User)

# Criar user e account
user =
  %User{}
  |> User.changeset(%{email: "stress@example.com", password: "test123"})
  |> Repo.insert!()

account =
  %Account{}
  |> Account.changeset(%{user_id: user.id, balance: Decimal.new("1000.00")})
  |> Repo.insert!()

IO.puts("🎯 Iniciando stress test...")
IO.puts("   Account ID: #{account.id}")
IO.puts("   Saldo inicial: $1000.00")
IO.puts("   Tentativas: 10 saques de $600 (apenas 1 pode passar)")
IO.puts("")

# Disparar 10 Tasks em paralelo (concorrência real)
tasks =
  1..10
  |> Enum.map(fn i ->
    Task.async(fn ->
      idempotency_key = "stress-withdraw-#{i}"

      Transactions.process_transaction(
        account.id,
        "withdraw",
        Decimal.new("600.00"),
        idempotency_key
      )
    end)
  end)

# Aguardar todas as tasks
results = Task.await_many(tasks, :infinity)

# Análise dos resultados
{successes, failures} =
  results
  |> Enum.split_with(fn
    {:ok, _} -> true
    {:error, _} -> false
  end)

IO.puts("📊 Resultados:")
IO.puts("   ✓ Sucessos: #{length(successes)}")
IO.puts("   ✗ Falhas: #{length(failures)}")
IO.puts("")

# Verificar tipo de erro
failure_types = Enum.map(failures, fn {:error, reason} -> reason end)

IO.puts("📋 Detalhes das falhas:")

failure_types
|> Enum.uniq()
|> Enum.each(fn reason ->
  count = Enum.count(failure_types, &(&1 == reason))
  IO.puts("   - #{reason}: #{count}x")
end)

# Verificar saldo final
final_account = Repo.get!(Account, account.id)
IO.puts("")
IO.puts("💰 Saldo final: $#{final_account.balance}")

# Validações
IO.puts("")
IO.puts("✅ Validações:")

if length(successes) == 1 do
  IO.puts("   ✓ Exatamente 1 saque bem-sucedido")
else
  IO.puts("   ✗ ERRO: Esperava 1 sucesso, obteve #{length(successes)}")
end

if length(failures) == 9 do
  IO.puts("   ✓ Exatamente 9 saques rejeitados")
else
  IO.puts("   ✗ ERRO: Esperava 9 falhas, obteve #{length(failures)}")
end

expected_balance = Decimal.new("400.00")

if final_account.balance == expected_balance do
  IO.puts("   ✓ Saldo final correto: $400.00")
else
  IO.puts("   ✗ ERRO: Saldo deveria ser $400.00, é #{final_account.balance}")
end

if Enum.all?(failure_types, &(&1 == :insufficient_funds)) do
  IO.puts("   ✓ Todas as falhas foram por saldo insuficiente")
else
  IO.puts("   ⚠ Nem todas falhas foram por :insufficient_funds")
end

# Teste passou?
if length(successes) == 1 && length(failures) == 9 &&
     final_account.balance == expected_balance &&
     Enum.all?(failure_types, &(&1 == :insufficient_funds)) do
  IO.puts("")
  IO.puts("🎉 STRESS TEST PASSOU!")
  IO.puts("   Pessimistic locking está funcionando corretamente.")
  System.halt(0)
else
  IO.puts("")
  IO.puts("❌ STRESS TEST FALHOU!")
  IO.puts("   Verifique a implementação de pessimistic locking.")
  System.halt(1)
end
