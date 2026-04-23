import { useState } from 'react'

export default function MoneyModal({ action, fundName, isPending, onClose, onSubmit }) {
  const [amount, setAmount] = useState('')
  // Set modal title based on action
  const title = action === 'deposit' ? 'Deposit' : action === 'withdraw' ? 'Withdraw' : `Invest in ${fundName}`

  return (
    <div className="modal-backdrop">
      <form
        className="modal"
        onSubmit={(event) => {
          event.preventDefault()
          onSubmit(amount)
        }}
      >
        <h2>{title}</h2>
        <label>
          Amount
          <input
            autoFocus
            min="0.01"
            step="0.01"
            type="number"
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            placeholder="100.00"
            required
          />
        </label>
        <div className="modal-actions">
          <button type="button" onClick={onClose} className="secondary-button">
            Cancel
          </button>
          <button type="submit" disabled={isPending} className="primary-button">
            Confirm
          </button>
        </div>
      </form>
    </div>
  )
}
