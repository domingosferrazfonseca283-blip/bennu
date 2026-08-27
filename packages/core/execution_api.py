from dataclasses import asdict
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from packages.core.sandbox_executor import SandboxExecutor
from apps.api.app.auth import Principal, require_role

router = APIRouter(prefix="/api/v1/executions", tags=["executions"])
executor = SandboxExecutor()

class ExecutionRequest(BaseModel):
    task_id: str
    operation: str
    approved: bool = False

@router.post("")
def execute(request: ExecutionRequest, principal: Principal = Depends(require_role("admin", "operator", "developer", "security"))):
    if not request.task_id.strip():
        raise HTTPException(status_code=400, detail="task_id is required")
    result = executor.execute(request.task_id, request.operation, request.approved)
    return {**asdict(result), "actor": principal.subject}
