from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.approval_center_api import center
from packages.core.execution_pipeline import ExecutionPipeline

router = APIRouter(prefix="/api/v1/execution", tags=["execution"])
pipeline = ExecutionPipeline(center)

@router.post("/run/{approval_id}")
def run(approval_id: str, principal: Principal = Depends(require_role("admin", "operator"))):
    try:
        outcome = pipeline.run(approval_id)
        return {
            "status": "executed",
            "permit": outcome.permit.__dict__,
            "result": outcome.result.__dict__,
            "audit": outcome.audit.__dict__,
        }
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
