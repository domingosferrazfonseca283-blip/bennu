from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .main import db
from .business_models import MarketplaceProduct
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/marketplace", tags=["marketplace"])

class Product(BaseModel):
    name: str
    kind: str
    price: float = 0
    currency: str = "EUR"

@router.get("/catalog")
def catalog(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "sales"))):
    products = session.scalars(select(MarketplaceProduct).order_by(MarketplaceProduct.id)).all()
    return {"products": products, "supported_kinds": ["digital-product", "script", "api", "ai-model", "website", "automation", "service", "plugin", "bot"]}

@router.post("/catalog")
def publish_product(product: Product, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "sales"))):
    item = MarketplaceProduct(**product.model_dump())
    session.add(item); session.commit(); session.refresh(item)
    return {"accepted": True, "product": item, "status": item.status}
