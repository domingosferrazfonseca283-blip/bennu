from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Literal

Decision = Literal["approved", "rejected", "pending"]

@dataclass
class ApprovalRequest:
    approval_id: str
    mission_id: str
    agent_id: str
    action: str
    reason: str
    status: Decision = "pending"
    reviewer: str | None = None
    reviewed_at: str | None = None

class ApprovalCenter:
    def __init__(self):
        self.requests: dict[str, ApprovalRequest] = {}

    def submit(self, request: ApprovalRequest) -> ApprovalRequest:
        if request.approval_id in self.requests:
            raise ValueError("approval already exists")
        self.requests[request.approval_id] = request
        return request

    def review(self, approval_id: str, decision: Literal["approved", "rejected"], reviewer: str) -> ApprovalRequest:
        request = self.requests.get(approval_id)
        if request is None:
            raise KeyError("approval not found")
        if request.status != "pending":
            raise ValueError("approval already reviewed")
        request.status = decision
        request.reviewer = reviewer
        request.reviewed_at = datetime.now(timezone.utc).isoformat()
        return request

    def list_pending(self):
        return [r for r in self.requests.values() if r.status == "pending"]
