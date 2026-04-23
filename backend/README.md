# Backend — Carteira Digital

Phoenix + Ecto + PostgreSQL com race conditions e idempotência tratadas.

## Setup

```bash
mix setup
mix ecto.create && mix ecto.migrate
mix run priv/repo/seeds.exs
mix phx.server
```

Servidor roda em `http://localhost:4000`

## Arquitetura

### Pesimistic Locking (Race Conditions)
- Saques/investimentos usam `SELECT ... FOR UPDATE` no Ecto
- Garante que apenas 1 transação por vez acessa a conta
- Valida saldo DENTRO da transaction

### Idempotência
- Cada requisição requer header `x-idempotency-key` (UUID)
- Constraint unique no banco garante que chave só insere 1x
- Duplicate request retorna HTTP 409

### GenServer de Preços
`Backend.Funds.PriceUpdater` atualiza `current_share_price` a cada 5s com variação aleatória.

## API

### Contas
```
GET  /api/accounts/:id
POST /api/accounts/:id/deposit
POST /api/accounts/:id/withdraw
```

### Fundos
```
GET  /api/funds
POST /api/funds/:id/invest
```

**Headers obrigatórios:** `x-idempotency-key: <uuid>`

## Testando

### Testes ExUnit (recomendado)
```bash
# Rodar todos os testes
mix test

# Rodar testes de transações apenas
mix test test/backend/transactions_test.exs

# Rodar testes dos controllers
mix test test/backend_web/controllers/
```

### Teste de Idempotência (script)
Valida que requisições duplicadas com mesma `x-idempotency-key` retornam 409:
```bash
mix run test_idempotency.exs
```

**O que testa:**
- Primeira requisição de saque com `idempotency_key` sucede
- Segunda requisição com MESMA chave falha com `:duplicate_request`
- Saldo é debitado apenas 1x (não duplicado)

### Teste de Stress — Race Conditions (script)
Dispara 10 saques simultâneos ($600 cada) em conta com $1000.
Apenas 1 deve passar (pessimistic locking funciona):

```bash
mix run test_stress_concurrent_withdrawals.exs
```

**O que testa:**
- ✓ Exatamente 1 saque bem-sucedido
- ✓ 9 saques rejeitados com `:insufficient_funds`
- ✓ Saldo final = $400 (apenas 1 debitado)
- ✓ Pessimistic locking (`FOR UPDATE`) está travando a conta corretamente

## Migrations

- `20260422000001_create_users.exs` — Users
- `20260422000002_create_accounts.exs` — Accounts (decimal balance, version)
- `20260422000003_create_transactions.exs` — Transactions (idempotency_key unique)
- `20260422000004_create_funds.exs` — Funds
- `20260422000005_create_investments.exs` — Investments
