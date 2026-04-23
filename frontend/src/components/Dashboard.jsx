import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Panel from './Panel'
import MoneyModal from './MoneyModal'
import { DEMO_ACCOUNT_ID, apiRequest, currency, toNumber, idempotencyKey } from '../utils'

export default function Dashboard() {
  const [modal, setModal] = useState(null)
  const queryClient = useQueryClient()

  const { data: account, isLoading } = useQuery({
    queryKey: ['account', DEMO_ACCOUNT_ID],
    queryFn: () => apiRequest(`/api/accounts/${DEMO_ACCOUNT_ID}`),
    refetchInterval: 3000,
  })

  const transactionMutation = useMutation({
    mutationFn: ({ action, amount }) =>
      apiRequest(`/api/accounts/${DEMO_ACCOUNT_ID}/${action}`, {
        method: 'POST',
        headers: { 'x-idempotency-key': idempotencyKey(action) },
        body: JSON.stringify({ amount }),
      }),
    onMutate: async ({ action, amount }) => {
      await queryClient.cancelQueries({ queryKey: ['account', DEMO_ACCOUNT_ID] })
      const previous = queryClient.getQueryData(['account', DEMO_ACCOUNT_ID])
      const numericAmount = toNumber(amount)

      if (previous) {
        queryClient.setQueryData(['account', DEMO_ACCOUNT_ID], {
          ...previous,
          balance: String(
            action === 'deposit'
              ? toNumber(previous.balance) + numericAmount
              : toNumber(previous.balance) - numericAmount,
          ),
        })
      }

      return { previous }
    },
    onError: (_error, _variables, context) => {
      if (context?.previous) {
        queryClient.setQueryData(['account', DEMO_ACCOUNT_ID], context.previous)
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['account', DEMO_ACCOUNT_ID] })
    },
  })

  if (isLoading) {
    return <Panel title="Loading Wallet">Fetching balance and transactions...</Panel>
  }

  return (
    <section className="dashboard-grid">
      <div className="balance-card">
        <span className="eyebrow">Demo account #{DEMO_ACCOUNT_ID}</span>
        <h2>Available balance</h2>
        <strong>{currency.format(toNumber(account.balance))}</strong>
        <div className="action-row">
          <button onClick={() => setModal('deposit')} className="primary-button">
            Deposit
          </button>
          <button onClick={() => setModal('withdraw')} className="danger-button">
            Withdraw
          </button>
        </div>
        {transactionMutation.isError && <p className="form-error">{transactionMutation.error.message}</p>}
      </div>
      <Panel title="Recent transactions">
        <div className="transaction-list">
          {account.transactions.map((transaction) => (
            <div key={transaction.id} className="transaction-item">
              <span>{transaction.type}</span>
              <strong>{currency.format(toNumber(transaction.amount))}</strong>
            </div>
          ))}
        </div>
      </Panel>
      {modal && (
        <MoneyModal
          action={modal}
          isPending={transactionMutation.isPending}
          onClose={() => setModal(null)}
          onSubmit={(amount) => {
            transactionMutation.mutate({ action: modal, amount })
            setModal(null)
          }}
        />
      )}
    </section>
  )
}
