from packages.core.agent_runtime import AgentDefinition, AgentRuntime

DEFAULT_AGENTS = (
    AgentDefinition("agent-ceo", "Bennu CEO", "ceo", ("analyze_metrics", "plan_strategy"), ("analyze_metrics",)),
    AgentDefinition("agent-commercial", "Bennu Commercial", "commercial", ("analyze_leads", "draft_proposal"), ()),
    AgentDefinition("agent-security", "Bennu Security", "security", ("analyze_security_events", "assess_risk"), ("analyze_security_events",)),
    AgentDefinition("agent-developer", "Bennu Developer", "developer", ("analyze_code", "draft_patch"), ()),
    AgentDefinition("agent-finance", "Bennu Finance", "finance", ("analyze_revenue", "draft_report"), ("analyze_revenue",)),
    AgentDefinition("agent-marketing", "Bennu Marketing", "marketing", ("analyze_campaign", "draft_content"), ()),
)

def create_default_runtime() -> AgentRuntime:
    runtime = AgentRuntime()
    for agent in DEFAULT_AGENTS:
        runtime.register(agent)
    return runtime
