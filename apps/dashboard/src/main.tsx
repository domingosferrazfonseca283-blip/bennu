import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, Bot, Building2, Cloud, LockKeyhole, Terminal, Zap } from 'lucide-react';
import './styles.css';

const API = import.meta.env.VITE_BENNU_API ?? 'http://localhost:8000';
const cards = [['Security', 'security_score', LockKeyhole], ['Agents', 'agents', Bot], ['Tasks', 'tasks', Zap], ['Cloud', 'cloud', Cloud]] as const;

function App() {
  const [data, setData] = useState<any>({ security_score: 0, agents: 0, tasks: 0, cloud: 0, mode: 'CONNECTING' });
  useEffect(() => { fetch(`${API}/api/v1/system/status`).then(r => r.json()).then(setData).catch(() => setData((d:any) => ({...d, mode:'OFFLINE'}))); }, []);
  return <div className="shell"><aside><div className="brand">BENNU<span>OS</span></div><div className="online">● {data.mode === 'OFFLINE' ? 'CORE OFFLINE' : 'SYSTEM ONLINE'}</div>
    <nav>{[['Dashboard', Activity], ['AI', Bot], ['Security', LockKeyhole], ['Business', Building2], ['Agents', Bot], ['Cloud', Cloud], ['Terminal', Terminal]].map(([name, Icon]) => <button key={name as string}><Icon size={17}/>{name as string}</button>)}</nav></aside>
    <main><header><div><p className="eyebrow">INTELLIGENT OPERATING PLATFORM</p><h1>System Overview</h1></div><div className="mode">{String(data.mode).toUpperCase()}</div></header>
      <section className="grid">{cards.map(([title, key, Icon]) => <article className="card" key={title}><Icon size={20}/><p>{title}</p><strong>{data[key] ?? 0}{key === 'security_score' ? '/100' : ''}</strong></article>)}</section>
      <section className="panel"><div className="panel-title"><span>LIVE ACTIVITY</span><small>REAL TIME</small></div><div className="chart">{[35,55,42,70,48,82,60,91,66,76,52,88].map((h,i)=><i key={i} style={{height:`${h}%`}} />)}</div></section>
      <section className="bottom"><article className="panel"><div className="panel-title"><span>AI AGENTS</span><small>{data.agents} ACTIVE</small></div>{['CEO Agent','Security Agent','Developer Agent','Sales Agent'].map(a => <div className="agent" key={a}><span className="dot"/>{a}<em>STANDBY</em></div>)}</article><article className="panel"><div className="panel-title"><span>BENNU TERMINAL</span><small>SAFE</small></div><div className="terminal"><span>bennu &gt;</span> system status</div><div className="terminal">core: {data.mode}</div></article></section>
    </main></div>
}
createRoot(document.getElementById('root')!).render(<React.StrictMode><App /></React.StrictMode>);
