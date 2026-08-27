const API = window.BENNU_API || 'http://localhost:8000';
const TOKEN = window.BENNU_TOKEN || 'bennu-admin-dev';
const headers = { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };

async function loadAgents() {
  const response = await fetch(`${API}/api/v1/agents`, { headers });
  if (!response.ok) throw new Error('Unable to load agents');
  return response.json();
}

async function createAgent(name, role, autonomous = false) {
  const response = await fetch(`${API}/api/v1/agents`, {
    method: 'POST', headers,
    body: JSON.stringify({ name, role, autonomous })
  });
  if (!response.ok) throw new Error('Unable to create agent');
  return response.json();
}

window.BennuAgents = { loadAgents, createAgent };
