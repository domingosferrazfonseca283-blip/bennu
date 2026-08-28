from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.approval_center import ApprovalCenter

router = APIRouter(prefix="/api/v1/approvals", tags=["approvals"])
center = ApprovalCenter()

@router.get("")
def list_approvals(principal: Principal = Depends(require_role("admin", "operator"))):
    return {"items": [r.__dict__ for r in center.requests.values()]}

@router.post("/{approval_id}/review")
def review_approval(approval_id: str, body: dict, principal: Principal = Depends(require_role("admin", "operator"))):
    decision = body.get("decision")
    if decision not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="decision must be approved or rejected")
    try:
        result = center.review(approval_id, decision, principal.subject)
        return result.__dict__
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
