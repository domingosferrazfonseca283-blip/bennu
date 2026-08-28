from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.soc_core import SOCCore

router = APIRouter(prefix="/api/v1/soc", tags=["soc"])
soc = SOCCore()

@router.get("/overview")
def overview(principal: Principal = Depends(require_role("admin", "operator", "viewer"))):
    return soc.overview()

@router.get("/events")
def events(principal: Principal = Depends(require_role("admin", "operator", "viewer"))):
    return {"items": [e.__dict__ for e in soc.bus.recent()]}

@router.get("/alerts")
def alerts(principal: Principal = Depends(require_role("admin", "operator", "viewer"))):
    return {"items": [a.__dict__ for a in soc.alerts.alerts]}

@router.get("/incidents")
def incidents(principal: Principal = Depends(require_role("admin", "operator", "viewer"))):
    return {"items": [i.__dict__ for i in soc.incidents.incidents]}

@router.post("/incidents/{incident_id}/assign")
def assign(incident_id: str, body: dict, principal: Principal = Depends(require_role("admin", "operator"))):
    owner = body.get("owner")
    if not owner:
        raise HTTPException(status_code=400, detail="owner is required")
    try:
        return soc.incidents.assign(incident_id, owner).__dict__
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))

@router.post("/incidents/{incident_id}/resolve")
def resolve(incident_id: str, principal: Principal = Depends(require_role("admin", "operator"))):
    try:
        return soc.incidents.resolve(incident_id).__dict__
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
