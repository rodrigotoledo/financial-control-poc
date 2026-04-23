import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import MoneyModal from './MoneyModal'
import { DEMO_ACCOUNT_ID, apiRequest, currency, toNumber, idempotencyKey } from '../utils'

export default function InvestmentHub() {
  const [selectedFund, setSelectedFund] = useState(null)
  const queryClient = useQueryClient()

  const { data } = useQuery({
    queryKey: ['funds'],
    queryFn: () => apiRequest('/api/funds'),
    refetchInterval: 5000,
  })

  const investmentMutation = useMutation({
    mutationFn: ({ fundId, amount }) =>
      apiRequest(`/api/funds/${fundId}/invest`, {
        method: 'POST',
        headers: { 'x-idempotency-key': idempotencyKey('investment') },
        body: JSON.stringify({ account_id: DEMO_ACCOUNT_ID, amount }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['account', DEMO_ACCOUNT_ID] })
      queryClient.invalidateQueries({ queryKey: ['funds'] })
    },
  })

  const funds = data?.funds || []

  return (
    <section className="fund-section">
      <div className="section-heading">
        <span className="eyebrow">Polling TanStack every 5s</span>
        <h2>Funds in motion</h2>
      </div>
      <div className="fund-grid">
        {funds.map((fund) => {
          const change = toNumber(fund.change_percent)
          const positive = change >= 0
          return (
            <article key={fund.id} className="fund-card">
              <div>
                <span className="fund-code">FND-{String(fund.id).padStart(3, '0')}</span>
                <h3>{fund.name}</h3>
              </div>
              <strong>{currency.format(toNumber(fund.current_share_price))}</strong>
              <p className={positive ? 'positive' : 'negative'}>
                {positive ? '+' : ''}
                {change.toFixed(3)}% since last tick
              </p>
              <button onClick={() => setSelectedFund(fund)} className="ghost-button">
                Invest in this fund
              </button>
            </article>
          )
        })}
      </div>
      {investmentMutation.isError && <p className="form-error">{investmentMutation.error.message}</p>}
      {selectedFund && (
        <MoneyModal
          action="investment"
          fundName={selectedFund.name}
          isPending={investmentMutation.isPending}
          onClose={() => setSelectedFund(null)}
          onSubmit={(amount) => {
            investmentMutation.mutate({ fundId: selectedFund.id, amount })
            setSelectedFund(null)
          }}
        />
      )}
    </section>
  )
}
