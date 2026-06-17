from __future__ import annotations
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.deps import get_current_user
from app.models import Alert, User
from app.schemas import AlertOut
router = APIRouter(prefix="/api/v1/alerts", tags=["alerts"])
@router.get("", response_model=list[AlertOut])
async def list_alerts(
    limit: int = Query(50, ge=1, le=500),
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Alert)
        .where(Alert.user_id == current.id)
        .order_by(Alert.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())