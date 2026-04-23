# Frontend - Carteira Digital

React + Vite + Tailwind CSS

## Setup

```bash
npm install
npm run dev
```

Acessa `http://localhost:5173`

## Estrutura

- **Dashboard:** Saldo total + últimas transações
- **Investment Hub:** Cards dos fundos com variação %
- **Modais:** Depósito e Saque

## Tailwind

Não precisa de CLI local. Use a **extensão Tailwind CSS (IntelliSense)** no VS Code.

## TODO

- [ ] Integrar com API do backend
- [ ] Adicionar Optimistic Updates no TanStack Query
- [ ] Implementar polling de fundos a cada 5s
- [ ] Adicionar `x-idempotency-key` nos headers das transações
- [ ] Validação de formulários
- [ ] Toast notifications (erro/sucesso)
