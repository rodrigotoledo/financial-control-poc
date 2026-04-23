# 🗣️ How to Present This Project (Interview Script)

You can use the following script to confidently present this project in interviews or technical discussions:

---

**Project Overview:**

"This project is a robust digital wallet system built with Phoenix (Elixir) and React. It demonstrates advanced handling of data integrity, concurrency, and real-world financial operations."

**Key Features:**

- Real-time balance and transaction updates (polling with TanStack Query)
- Safe deposits, withdrawals, and investments with idempotency keys
- Pessimistic locking to prevent race conditions and negative balances
- Automated stress tests to prove robustness under concurrent requests
- Modern UI with optimistic updates and error handling

**Why Idempotency and Locking?**

"In financial systems, duplicate or concurrent requests can cause serious inconsistencies. By requiring a unique idempotency key for each transaction, we ensure that repeated or retried requests are processed only once. Pessimistic locking at the database level guarantees that two withdrawals cannot overdraw the same account, even under heavy load."

**Stress Testing:**

"We include a stress test script that fires multiple concurrent requests. Only valid transactions succeed; others are safely rejected. This demonstrates the system's resilience to concurrency issues."

**Why Phoenix?**

"Phoenix and Ecto provide first-class support for database transactions, locking, and high concurrency, making them ideal for building reliable financial backends."

**Summary:**

"This project is not just a CRUD app—it is designed to handle real-world financial challenges, with a focus on correctness, safety, and performance."

---

Feel free to adapt this script to your style and the specifics of the interview. Good luck!

# 📚 Sobre este Projeto (em português)

Este projeto demonstra uma carteira digital robusta, construída com Phoenix (Elixir) no backend e React no frontend, com foco em integridade de dados, concorrência e resiliência.

**Pontos-chave:**

- **Race Conditions:**
  - O sistema utiliza bloqueio pessimista (pessimistic locking) nas operações críticas, como saques, para garantir que duas requisições simultâneas não causem saldo negativo. Isso é feito com transações e o comando `FOR UPDATE` no banco de dados.

- **Idempotência:**
  - Todas as operações de depósito, saque e investimento exigem um `x-idempotency-key` único. Assim, se o usuário clicar duas vezes ou a requisição for reenviada, a operação só será processada uma vez, evitando débitos ou créditos duplicados.

- **Testes de Stress:**
  - O projeto inclui um script de stress test que dispara várias requisições concorrentes (por exemplo, 20 saques simultâneos). O esperado é que apenas as transações possíveis sejam realizadas, e as demais recebam erro de saldo insuficiente, provando a robustez contra concorrência.

- **Vantagens do Phoenix:**
  - O Phoenix, junto com Ecto, facilita a implementação de transações seguras, bloqueios de linha e alta performance para lidar com múltiplas conexões simultâneas. Isso torna a stack ideal para sistemas financeiros que exigem consistência e escalabilidade.

**Resumo:**

Com essas práticas, o sistema evita problemas clássicos de concorrência e duplicidade, garantindo que o saldo do usuário nunca fique inconsistente, mesmo sob alta carga. O stress test automatizado comprova a robustez da solução.

Estude o código, rode os testes de stress e observe como Phoenix/Ecto e as técnicas de idempotência e locking resolvem problemas reais de sistemas financeiros!

# 🚀 Fullstack Challenge: Phoenix, React & Financial Transactions

This guide helps you build a high-quality MVP focused on data integrity, concurrency, and architecture.

It demonstrates a digital wallet system with deposits, withdrawals, and fund investments, handling race conditions and idempotency.

---

## ⚡ Quick Start

```bash
# Start the full stack (Postgres, Phoenix, React)
docker compose up --build
```

Access:
- Frontend: http://localhost:5173
- Backend:  http://localhost:4000
- Postgres: localhost:5432

Demo account already created:
- Email: demo@financial-control.local
- Password: demo-password
- Balance: $1,250.50

See [DOCKER.md](DOCKER.md) for more details and troubleshooting.

---

## 🚦 Stress Test: Simulate Concurrent Transactions

You can run a stress test to simulate many concurrent withdrawals or deposits:

```bash
# Run the stress test (default: 20 concurrent withdrawals of $10 from account 1)
docker compose run --rm stress

# Customize parameters (example: 50 deposits of $5)
docker compose run --rm -e ACTION=deposit -e AMOUNT=5.00 -e REQUESTS=50 stress
```

You can also run the script manually:
```bash
chmod +x scripts/stress_transactions.sh
API_URL=http://localhost:4000 ACCOUNT_ID=1 AMOUNT=10.00 REQUESTS=20 ACTION=withdraw ./scripts/stress_transactions.sh
```

---

## 🏗️ 1. Infraestrutura (Docker)

O primeiro passo é garantir que o ambiente suba com um único comando.

- **Crie um `docker-compose.yml`:**
  - **Postgres:** Banco de dados.
  - **Phoenix App:** Sua API.

> **Dica:** Use `healthcheck` no Postgres para que o Phoenix só tente rodar as migrations quando o banco estiver pronto.

---

## 🗄️ 2. Modelagem de Dados (Back-end)

Dinheiro é coisa séria.  
**Regra de ouro:** Use o tipo `:decimal` no Ecto (mapeia para `numeric` no Postgres). Nunca use Float.

**Esquema Sugerido:**

- **Users:** `id`, `email`, `password_hash`
- **Accounts:** `id`, `user_id`, `balance` (decimal), `version` (integer para optimistic locking)
- **Transactions:** `id`, `account_id`, `type` (enum: deposit, withdraw, investment), `amount`, `idempotency_key` (unique index)
- **Funds:** `id`, `name`, `current_share_price`
- **Investments:** `id`, `user_id`, `fund_id`, `shares_count`, `invested_amount`

---

## 🛡️ 3. A Lógica de Negócio Crítica (Phoenix/Ecto)

### Tratando Race Conditions (Pessimistic Locking)

Ao sacar dinheiro, você precisa travar a linha da conta para que duas requisições simultâneas não causem saldo negativo.

```elixir
# No seu Contexto de Account
def transfer_money(account_id, amount) do
  Repo.transaction(fn ->
    account = Repo.get!(Account, account_id) |> lock("FOR UPDATE")
    if Decimal.compare(account.balance, amount) != :lt do
      # Prossiga com o saque
    else
      Repo.rollback(:insufficient_funds)
    end
  end)
end
```

### Garantindo Idempotência

Para evitar cliques duplos no front-end:

- Receba um `x-idempotency-key` no header.
- Tente inserir na tabela de Transactions (que tem um índice único nessa chave).
- Se der erro de violação de constraint, retorne o erro amigável (ou o resultado anterior) sem processar o débito novamente.

---

## 📊 4. Rentabilidade de Fundos

Para simular a rentabilidade:

- Crie um GenServer no Phoenix que, a cada 5 segundos, atualiza o `current_share_price` de cada fundo com uma pequena variação aleatória.
- No Front-end, o TanStack Query fará o polling dessa info para atualizar os gráficos.

---

## 🎨 5. Front-end (React + Vite + Tailwind)

**Estrutura de UI:**

- **Dashboard:** Saldo total e lista de transações recentes.
- **Investment Hub:** Cards dos fundos com a variação (use cores: verde para alta, vermelho para baixa).
- **Modais:** Formulários simples para Depósito/Saque.

**TanStack Query (O Diferencial):**

- Use `useMutation` para as transações.
- Implemente Optimistic Updates: Quando o usuário clica em "Sacar $10", a UI já desconta o valor imediatamente. Se a API der erro, a UI volta ao estado anterior (rollback).

---

## 🧪 6. Scripts de Stress Test

Prepare um script simples em Elixir ou JS para disparar 10 requisições de saque de $10 ao mesmo tempo em uma conta que só tem $15.

**Sucesso esperado:** Apenas 1 transação passa, as outras 9 retornam erro de saldo insuficiente ou concorrência. Isso prova que seu sistema é robusto.