from fastapi import APIRouter, Depends
from pydantic import BaseModel
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/marketplace", tags=["marketplace"])

class Product(BaseModel):
    name: str
    kind: str
    price: float = 0
    currency: str = "EUR"

@router.get("/catalog")
def catalog(principal: Principal = Depends(require_role("viewer", "operator", "admin", "sales"))):
    return {"products": [], "supported_kinds": ["digital-product", "script", "api", "ai-model", "website", "automation", "service", "plugin", "bot"]}

@router.post("/catalog")
def publish_product(product: Product, principal: Principal = Depends(require_role("admin", "sales"))):
    return {"accepted": True, "product": product, "status": "draft"}
