from dataclasses import dataclass
from packages.core.approval_center import ApprovalCenter
from packages.core.execution_gate import ExecutionGate, ExecutionPermit
from packages.core.allowlisted_executor import AllowlistedExecutor, ExecutionResult
from packages.core.execution_audit import ExecutionAudit, ExecutionAuditEvent

@dataclass(frozen=True)
class PipelineResult:
    permit: ExecutionPermit
    result: ExecutionResult
    audit: ExecutionAuditEvent

class ExecutionPipeline:
    """Single controlled path: approval -> permit -> allowlist -> execution -> audit."""
    def __init__(self, approvals: ApprovalCenter | None = None):
        self.approvals = approvals or ApprovalCenter()
        self.gate = ExecutionGate(self.approvals)
        self.executor = AllowlistedExecutor()
        self.audit = ExecutionAudit()

    def run(self, approval_id: str) -> PipelineResult:
        permit = self.gate.authorize(approval_id)
        result = self.executor.execute(permit)
        event = self.audit.record(permit, result)
        return PipelineResult(permit, result, event)
