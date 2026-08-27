import { useEffect, useState } from 'react';
import './styles.css';

const API = import.meta.env.VITE_BENNU_API ?? 'http://localhost:8000';

export default function App() {
  const [status, setStatus] = useState({ security_score: 0, agents: 0, tasks: 0, mode: 'connecting' });
  const [online, setOnline] = useState(false);

  useEffect(() => {
    fetch(`${API}/api/v1/system/status`)
      .then(r => r.json())
      .then(data => { setStatus(data); setOnline(true); })
      .catch(() => setOnline(false));
  }, []);

  return <div className="shell">
    <aside><div className="brand"><span>◈</span> BENNU</div><nav>
      {['Dashboard','AI Core','Security','Agents','Automation','Business','Cloud','Terminal','Market','Settings'].map((x,i)=><div className={i===0?'active':''} key={x}>{x}</div>)}
    </nav><div className="ghost">GHOST MODE<br/><b>STANDBY</b></div></aside>
    <main><header><div><small>BENNU OPERATING SYSTEM</small><h1>Command Center</h1></div><div className="online">● {online?'SYSTEM ONLINE':'CORE OFFLINE'}</div></header>
      <section className="grid">
        <Card title="Security Score" value={`${status.security_score}/100`} sub="Risk posture" />
        <Card title="Active Agents" value={status.agents} sub="Autonomous workers" />
        <Card title="Tasks" value={status.tasks} sub="Core workload" />
        <Card title="Mode" value={String(status.mode).toUpperCase()} sub="Execution policy" />
      </section>
      <section className="panels"><div className="panel"><h2>Live Activity</h2><div className="chart">{[35,55,42,70,48,82,60,91,66,76,52,88].map((h,i)=><i key={i} style={{height:`${h}%`}} />)}</div><div className="muted">Waiting for Bennu Core events…</div></div>
      <div className="panel"><h2>Agent Matrix</h2>{['CEO','SECURITY','DEVELOPER','SALES','FINANCE'].map(a=><div className="agent" key={a}><span>● {a}</span><b>STANDBY</b></div>)}</div></section>
      <section className="terminal"><div><span>BENNU &gt;</span> system status</div><p>Core connection: {online?'established':'unavailable'}</p><p>Execution policy: approval-required</p></section>
    </main></div>
}
function Card({title,value,sub}:{title:string,value:any,sub:string}){return <div className="card"><small>{title}</small><strong>{value}</strong><span>{sub}</span></div>}
