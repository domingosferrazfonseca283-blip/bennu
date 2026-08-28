from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.approval_center_api import center
from packages.core.execution_gate import ExecutionGate

router = APIRouter(prefix="/api/v1/execution", tags=["execution"])
gate = ExecutionGate(center)

@router.post("/authorize/{approval_id}")
def authorize(approval_id: str, principal: Principal = Depends(require_role("admin", "operator"))):
    try:
        permit = gate.authorize(approval_id)
        return {"authorized": True, "permit": permit.__dict__}
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
