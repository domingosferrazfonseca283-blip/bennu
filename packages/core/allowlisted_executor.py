from dataclasses import dataclass
from packages.core.execution_gate import ExecutionPermit

ALLOWED_ACTIONS = frozenset({
    "analyze_metrics", "plan_strategy", "analyze_leads", "draft_proposal",
    "analyze_security_events", "assess_risk", "analyze_code", "draft_patch",
    "analyze_revenue", "draft_report", "analyze_campaign", "draft_content",
})

@dataclass(frozen=True)
class ExecutionResult:
    approval_id: str
    action: str
    status: str
    message: str

class AllowlistedExecutor:
    """Executes only named, application-defined operations; no shell or arbitrary code."""
    def execute(self, permit: ExecutionPermit) -> ExecutionResult:
        if permit.action not in ALLOWED_ACTIONS:
            raise PermissionError("action is not allowlisted")
        return ExecutionResult(permit.approval_id, permit.action, "accepted", "execution admitted by allowlist")
