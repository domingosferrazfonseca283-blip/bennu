from dataclasses import dataclass
from packages.core.agent_runtime import AgentRuntime, AgentContext, AgentDecision
from packages.core.default_agents import create_default_runtime
from packages.core.mission_engine import Mission

@dataclass(frozen=True)
class Assignment:
    task_id: str
    agent_id: str
    role: str
    decision: AgentDecision

class MissionAgentAssignmentEngine:
    """Maps planned mission tasks to registered agents without executing tools."""
    def __init__(self, runtime: AgentRuntime | None = None):
        self.runtime = runtime or create_default_runtime()

    def assign(self, mission: Mission) -> list[Assignment]:
        result: list[Assignment] = []
        for task in mission.tasks:
            matches = [a for a in self.runtime.agents.values() if a.role == task.agent_role]
            if not matches:
                raise ValueError(f"no agent registered for role: {task.agent_role}")
            agent = matches[0]
            action = self._action_for(task.id, agent.role)
            decision = self.runtime.decide(agent.agent_id, action, AgentContext(mission.id, mission.objective))
            result.append(Assignment(task.id, agent.agent_id, agent.role, decision))
        return result

    @staticmethod
    def _action_for(task_id: str, role: str) -> str:
        defaults = {
            "ceo": "analyze_metrics", "commercial": "analyze_leads",
            "security": "analyze_security_events", "developer": "analyze_code",
            "finance": "analyze_revenue", "marketing": "analyze_campaign",
        }
        return defaults.get(role, task_id)
