import React from 'react';
import ReactDOM from 'react-dom/client';
import './styles.css';

const caseData = {
  caseNumber: 'CHD-2026-041',
  sampleId: 'NP-CHD-2026-000128',
  fieldResult: 'PRESUMPTIVE',
  fieldTarget: 'BUFFALO DETECTED',
  labResult: 'CONFIRMATORY',
  labTarget: 'BUFFALO',
  status: 'SEALED FOR FSL CONFIRMATION'
};

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://neural-patrol-1.onrender.com';

function App() {
  const [apiStatus, setApiStatus] = React.useState('Checking backend...');

  React.useEffect(() => {
    fetch(`${API_BASE_URL}/health`)
      .then((res) => res.json())
      .then((data) => setApiStatus(`API Live: ${data.service || 'SpeciesTrace'}`))
      .catch(() => setApiStatus('API Standby'));
  }, []);

  return (
    <div className="portal-shell">
      <aside className="sidebar">
        <div className="brand">SPECIESTRACE</div>
        <nav>
          <button className="nav active">Dashboard</button>
          <button className="nav">Case Intake</button>
          <button className="nav">Audit Log</button>
          <button className="nav">Lab Results</button>
        </nav>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <div>
            <p className="eyebrow">AUTHORIZED FSL &bull; <span style={{ color: '#10b981', fontWeight: 600 }}>{apiStatus}</span></p>
            <h1>Case Overview</h1>
          </div>
          <button className="primary-button">Record Confirmatory Result</button>
        </header>


        <section className="summary-grid">
          <div className="card">
            <p className="label">CASE ID</p>
            <h2>{caseData.caseNumber}</h2>
          </div>
          <div className="card">
            <p className="label">SAMPLE ID</p>
            <h2>{caseData.sampleId}</h2>
          </div>
          <div className="card">
            <p className="label">PHYSICAL SAMPLE</p>
            <h2>{caseData.status}</h2>
          </div>
        </section>

        <section className="result-grid">
          <div className="card result-card field">
            <p className="result-label">FIELD RESULT</p>
            <h3>PRESUMPTIVE</h3>
            <div className="big-value">{caseData.fieldTarget}</div>
            <small>Not a final forensic confirmation. Original evidence remains subject to authorized laboratory testing.</small>
          </div>

          <div className="card result-card lab">
            <p className="result-label">LAB RESULT</p>
            <h3>CONFIRMATORY</h3>
            <div className="big-value">{caseData.labTarget}</div>
            <small>Final forensic result recorded after authorized laboratory confirmation.</small>
          </div>
        </section>

        <section className="timeline card">
          <h3>Digital Chain of Custody</h3>
          <ul>
            <li><span>09:42</span><strong>Sample registered</strong><em>Officer ID: OFR-041</em></li>
            <li><span>09:45</span><strong>Sealed and packaged</strong><em>Evidence preservation recorded</em></li>
            <li><span>09:48</span><strong>Field test started</strong><em>NP FIELD UNIT 01</em></li>
            <li><span>10:12</span><strong>Field result recorded</strong><em>Presumptive target flagged</em></li>
            <li><span>10:18</span><strong>Sample dispatched for confirmation</strong><em>Authorized FSL handoff</em></li>
          </ul>
        </section>
      </main>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
