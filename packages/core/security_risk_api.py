from fastapi import APIRouter, Depends
from apps.api.app.auth import Principal, require_role
from packages.core.risk_engine import RiskEngine
from packages.core.security_events import SecurityEvent, Severity

router = APIRouter(prefix="/api/v1/security", tags=["security"])
engine = RiskEngine()

@router.post("/risk/assess")
def assess_risk(events: list[dict], principal: Principal = Depends(require_role("admin", "operator", "security"))):
    parsed = [SecurityEvent(event_id=str(e["event_id"]), event_type=str(e["event_type"]), severity=e["severity"] as Severity, source=str(e["source"]), resource=str(e["resource"]), message=str(e["message"]), timestamp=str(e["timestamp"])) for e in events]
    return engine.assess(parsed).__dict__
