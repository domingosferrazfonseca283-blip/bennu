from dataclasses import dataclass
from packages.core.approval_center import ApprovalCenter

@dataclass(frozen=True)
class ExecutionPermit:
    approval_id: str
    mission_id: str
    agent_id: str
    action: str

class ExecutionGate:
    """Narrow gate: only an approved request can produce a permit for downstream execution."""
    def __init__(self, approvals: ApprovalCenter):
        self.approvals = approvals

    def authorize(self, approval_id: str) -> ExecutionPermit:
        request = self.approvals.requests.get(approval_id)
        if request is None:
            raise KeyError("approval not found")
        if request.status != "approved":
            raise PermissionError("execution requires an approved request")
        return ExecutionPermit(request.approval_id, request.mission_id, request.agent_id, request.action)
