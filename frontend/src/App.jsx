
import { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Dashboard from './components/Dashboard';
import InvestmentHub from './components/InvestmentHub';
import AboutPanel from './components/AboutPanel';

const queryClient = new QueryClient();

function AppShell() {
  const [tab, setTab] = useState('dashboard');
  return (
    <div className="app-shell">
      <header className="hero">
        <div>
          <span className="eyebrow">Phoenix + React</span>
          <h1>Financial Control</h1>
          <p>Wallet with deposits, withdrawals, investments, idempotency, and concurrency under control.</p>
        </div>
      </header>
      <nav className="tabs">
        <button onClick={() => setTab('dashboard')} className={tab === 'dashboard' ? 'active' : ''}>
          Dashboard
        </button>
        <button onClick={() => setTab('investments')} className={tab === 'investments' ? 'active' : ''}>
          Funds
        </button>
        <button onClick={() => setTab('about')} className={tab === 'about' ? 'active' : ''}>
          About this...
        </button>
      </nav>
      <main>
        {tab === 'dashboard' && <Dashboard />}
        {tab === 'investments' && <InvestmentHub />}
        {tab === 'about' && <AboutPanel />}
      </main>
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppShell />
    </QueryClientProvider>
  );
}
