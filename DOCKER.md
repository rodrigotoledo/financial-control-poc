# Docker Setup — Carteira Digital

Tudo em um comando:

```bash
docker compose up --build
```

## Serviços

| Serviço | Port | URL |
|---|---|---|
| Frontend (Vite) | 5173 | http://localhost:5173 |
| Backend (Phoenix) | 4000 | http://localhost:4000 |
| Database (PostgreSQL) | 5432 | localhost:5432 |

## Primeiro acesso

1. Frontend carrega e proxeia `/api` para backend automaticamente
2. Backend cria migrations na primeira execução
3. Postgres já tem banco `backend_dev` criado

## Features

- ✅ Hot reload: código do frontend e backend recarrega automaticamente
- ✅ Volumes persistentes: dados do banco não se perdem ao `down`
- ✅ Healthcheck: backend aguarda Postgres estar pronto antes de subir
- ✅ Logs: `docker compose logs -f` para acompanhar

## Comandos úteis

```bash
# Rodar tudo
docker compose up --build

# Rodar em background
docker compose up -d --build

# Ver logs
docker compose logs -f

# Ver logs de um serviço
docker compose logs -f backend

# Parar tudo
docker compose down

# Remover volumes (limpa dados)
docker compose down -v

# Executar comando no container
docker compose exec backend mix test
docker compose exec backend mix run priv/repo/seeds.exs
```

## Troubleshooting

**"Address already in use"**
```bash
# Mude as ports em docker-compose.yml
# Ex: "5173:5173" → "5174:5173"
```

**"Postgres não inicia"**
```bash
# Remova o volume e tente novamente
docker compose down -v
docker compose up --build
```

**"Backend não conecta no Postgres"**
```bash
# Verifique logs
docker compose logs backend

# Ping do container
docker compose exec backend ping db
```

## ✅ Status

- **Frontend:** React + Vite, servindo em `http://localhost:5173`
- **Backend:** Phoenix + Ecto, servindo em `http://localhost:4000`
- **Database:** PostgreSQL, com dados de demo já seeded
- **API:** Deposits e withdrawals funcionando ✅
- **Hot reload:** Habilitado para código backend e frontend

## Desenvolvimento

Edite arquivos localmente. O código é montado como volume (`./backend:/app`), então mudanças aparecem automaticamente.

Para atualizar dependências:
```bash
# Backend
docker compose exec backend mix deps.get

# Frontend  
docker compose exec frontend npm install
```

## Demo Account

Após `docker compose up --build`, a seed já popula o banco com dados iniciais:

**Email:** `demo@financial-control.local`  
**Senha:** `demo-password`  
**Saldo Inicial:** `R$ 1.250,50`

### Testando a API

```bash
# Listar fundos
curl http://localhost:4000/api/funds | jq

# Obter conta
curl http://localhost:4000/api/accounts/1 | jq

# Fazer depósito
curl -X POST http://localhost:4000/api/accounts/1/deposit \
  -H "Content-Type: application/json" \
  -H "x-idempotency-key: deposit-001" \
  -d '{"amount": "500.00"}' | jq

# Fazer saque
curl -X POST http://localhost:4000/api/accounts/1/withdraw \
  -H "Content-Type: application/json" \
  -H "x-idempotency-key: withdraw-001" \
  -d '{"amount": "100.00"}' | jq
```
