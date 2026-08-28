from dataclasses import dataclass, field
from typing import Literal

AgentRole = Literal["ceo", "commercial", "security", "developer", "finance", "marketing"]

@dataclass(frozen=True)
class AgentDefinition:
    agent_id: str
    name: str
    role: AgentRole
    capabilities: tuple[str, ...] = ()
    permissions: tuple[str, ...] = ()

@dataclass
class AgentContext:
    mission_id: str | None = None
    objective: str = ""
    metadata: dict = field(default_factory=dict)

@dataclass
class AgentDecision:
    agent_id: str
    action: str
    requires_approval: bool
    reason: str

class AgentRuntime:
    """Safe agent registry and decision boundary. It does not execute arbitrary tools."""
    def __init__(self):
        self.agents: dict[str, AgentDefinition] = {}

    def register(self, agent: AgentDefinition) -> AgentDefinition:
        if agent.agent_id in self.agents:
            raise ValueError("agent already registered")
        self.agents[agent.agent_id] = agent
        return agent

    def get(self, agent_id: str) -> AgentDefinition | None:
        return self.agents.get(agent_id)

    def decide(self, agent_id: str, action: str, context: AgentContext) -> AgentDecision:
        agent = self.agents.get(agent_id)
        if agent is None:
            raise KeyError("agent not found")
        allowed = action in agent.capabilities
        if not allowed:
            return AgentDecision(agent_id, action, True, "capability not granted")
        return AgentDecision(agent_id, action, action not in agent.permissions, "approval policy applies")
