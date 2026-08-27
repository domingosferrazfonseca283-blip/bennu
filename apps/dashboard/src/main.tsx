import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, Bot, Building2, Cloud, LockKeyhole, Terminal, Zap, Check, X } from 'lucide-react';
import './styles.css';

const API = import.meta.env.VITE_BENNU_API ?? 'http://localhost:8000';
const TOKEN = import.meta.env.VITE_BENNU_TOKEN ?? 'bennu-admin-dev';
const headers = { Authorization: `Bearer ${TOKEN}` };
const cards = [['Security', 'security_score', LockKeyhole], ['Agents', 'agents', Bot], ['Tasks', 'tasks', Zap], ['Cloud', 'cloud', Cloud]] as const;

type Approval = { id:number; command:string; status:string; dry_run:boolean };

function App() {
  const [data, setData] = useState<any>({ security_score: 0, agents: 0, tasks: 0, cloud: 0, mode: 'CONNECTING' });
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [events, setEvents] = useState<any[]>([]);
  const [error, setError] = useState('');

  const load = async () => {
    try {
      const [status, queue, audit] = await Promise.all([
        fetch(`${API}/api/v1/system/status`, { headers }),
        fetch(`${API}/api/v1/approvals`, { headers }),
        fetch(`${API}/api/v1/audit`, { headers })
      ]);
      if (![status, queue, audit].every(r => r.ok)) throw new Error('API authentication or availability error');
      setData(await status.json()); setApprovals(await queue.json()); setEvents(await audit.json()); setError('');
    } catch (e) { setData((d:any) => ({...d, mode:'OFFLINE'})); setError('Core offline or token inválido'); }
  };
  useEffect(() => { load(); const timer = setInterval(load, 5000); return () => clearInterval(timer); }, []);

  const decide = async (id:number, action:'approve'|'reject') => {
    const r = await fetch(`${API}/api/v1/approvals/${id}/${action}`, { method:'POST', headers:{...headers,'Content-Type':'application/json'}, body:JSON.stringify({reason:`Dashboard ${action}`}) });
    if (!r.ok) { setError(`Não foi possível ${action === 'approve' ? 'aprovar' : 'rejeitar'} a tarefa`); return; }
    load();
  };

  return <div className="shell"><aside><div className="brand">BENNU<span>OS</span></div><div className="online">● {data.mode === 'OFFLINE' ? 'CORE OFFLINE' : 'SYSTEM ONLINE'}</div>
    <nav>{[['Dashboard', Activity], ['AI', Bot], ['Security', LockKeyhole], ['Business', Building2], ['Agents', Bot], ['Cloud', Cloud], ['Terminal', Terminal]].map(([name, Icon]) => <button key={name as string}><Icon size={17}/>{name as string}</button>)}</nav></aside>
    <main><header><div><p className="eyebrow">INTELLIGENT OPERATING PLATFORM</p><h1>Command Center</h1></div><div className="mode">{String(data.mode).toUpperCase()}</div></header>
      {error && <div className="notice">{error}</div>}
      <section className="grid">{cards.map(([title, key, Icon]) => <article className="card" key={title}><Icon size={20}/><p>{title}</p><strong>{data[key] ?? 0}{key === 'security_score' ? '/100' : ''}</strong></article>)}</section>
      <section className="bottom"><article className="panel"><div className="panel-title"><span>APPROVAL QUEUE</span><small>{approvals.length} PENDING</small></div>{approvals.length === 0 ? <div className="empty">No pending approvals</div> : approvals.map(a => <div className="approval" key={a.id}><div><strong>Task #{a.id}</strong><p>{a.command}</p></div><div><button className="icon approve" onClick={() => decide(a.id,'approve')}><Check size={16}/></button><button className="icon reject" onClick={() => decide(a.id,'reject')}><X size={16}/></button></div></div>)}</article>
      <article className="panel"><div className="panel-title"><span>LIVE AUDIT</span><small>5s REFRESH</small></div>{events.slice(0,6).map((e:any,i) => <div className="event" key={i}><span className="dot"/>{e.action ?? 'event'} · {e.actor ?? 'system'}</div>)}{events.length===0 && <div className="empty">No audit events</div>}</article></section>
      <section className="panel terminal-panel"><div className="panel-title"><span>BENNU TERMINAL</span><small>SAFE</small></div><div className="terminal"><span>bennu &gt;</span> system status</div><div className="terminal">core: {data.mode}</div></section>
    </main></div>
}
createRoot(document.getElementById('root')!).render(<React.StrictMode><App /></React.StrictMode>);
