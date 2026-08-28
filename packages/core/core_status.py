from .ai_gateway import AIGateway
from .default_agents import DEFAULT_AGENTS
from packages.agents.tool_registry import default_registry


def get_core_status() -> dict:
    registry = default_registry()
    return {
        "ai": AIGateway().status(),
        "agents": {"count": len(DEFAULT_AGENTS), "roles": [agent.role for agent in DEFAULT_AGENTS]},
        "tools": {"count": len(registry.list()), "names": [tool.name for tool in registry.list()]},
        "execution": {"requires_approval_for_high_risk": True, "authorized_scope_required": True},
    }
