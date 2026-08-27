import React from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, Bot, Building2, Cloud, LockKeyhole, Terminal, Zap } from 'lucide-react';
import './styles.css';

const cards = [
  ['Security', '100/100', LockKeyhole],
  ['Agents', '0', Bot],
  ['Tasks', '0', Zap],
  ['Cloud', '0', Cloud],
];

function App() {
  return <div className="shell">
    <aside><div className="brand">BENNU<span>OS</span></div><div className="online">● SYSTEM ONLINE</div>
      <nav>{[['Dashboard', Activity], ['AI', Bot], ['Security', LockKeyhole], ['Business', Building2], ['Agents', Bot], ['Cloud', Cloud], ['Terminal', Terminal]].map(([name, Icon]) => <button key={name as string}><Icon size={17}/>{name as string}</button>)}</nav>
    </aside>
    <main><header><div><p className="eyebrow">INTELLIGENT OPERATING PLATFORM</p><h1>System Overview</h1></div><div className="mode">SAFE MODE</div></header>
      <section className="grid">{cards.map(([title, value, Icon]) => <article className="card" key={title as string}><Icon size={20}/><p>{title as string}</p><strong>{value as string}</strong></article>)}</section>
      <section className="panel"><div className="panel-title"><span>LIVE ACTIVITY</span><small>REAL TIME</small></div><div className="chart"><div className="line"/><div className="point p1"/><div className="point p2"/><div className="point p3"/><div className="point p4"/></div></section>
      <section className="bottom"><article className="panel"><div className="panel-title"><span>AI AGENTS</span><small>0 ACTIVE</small></div>{['CEO Agent','Security Agent','Developer Agent','Sales Agent'].map(a => <div className="agent" key={a}><span className="dot"/>{a}<em>OFFLINE</em></div>)}</article><article className="panel"><div className="panel-title"><span>BENNU TERMINAL</span><small>READY</small></div><div className="terminal"><span>ben nu &gt;</span> await command...</div></article></section>
    </main>
  </div>
}
createRoot(document.getElementById('root')!).render(<React.StrictMode><App /></React.StrictMode>);
