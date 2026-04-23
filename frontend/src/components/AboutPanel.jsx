export default function AboutPanel() {
  return (
    <section className="panel">
      <h2>About this system</h2>
      <p>
        <strong>Financial Control</strong> is a demo application built with Phoenix (Elixir) and React. It simulates a digital wallet with the following features:
      </p>
      <ul>
        <li>• Real-time balance updates and transaction history</li>
        <li>• Deposit and withdraw operations with idempotency (safe to retry)</li>
        <li>• Investment in funds with live price changes</li>
        <li>• Concurrency-safe operations (handles multiple requests correctly)</li>
        <li>• Modern UI with dark mode and USD currency</li>
      </ul>
      <p>
        The backend uses Ecto and PostgreSQL for data integrity, and all operations are protected against race conditions. The frontend uses React and TanStack Query for fast, reactive updates.
      </p>
    </section>
  )
}
