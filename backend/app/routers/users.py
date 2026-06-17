from __future__ import annotations
from fastapi import APIRouter, Depends
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.deps import get_current_user
from app.models import (
    Alert,
    ChatMessage,
    DataDeletionRequest,
    Device,
    HealthProfile,
    Measurement,
    User,
)
from app.schemas import (
    DeletionRequestOut,
    HealthProfileIn,
    HealthProfileOut,
)
from app.services import resend_service
router = APIRouter(prefix="/api/v1/users", tags=["users"])
async def _get_or_create_profile(db: AsyncSession, user: User) -> HealthProfile:
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        profile = HealthProfile(user_id=user.id)
        db.add(profile)
        await db.commit()
        await db.refresh(profile)
    return profile
@router.get("/profile", response_model=HealthProfileOut)
async def get_profile(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    profile = await _get_or_create_profile(db, current)
    return _profile_out(profile)
@router.put("/profile", response_model=HealthProfileOut)
async def update_profile(
    payload: HealthProfileIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_or_create_profile(db, current)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    await db.commit()
    await db.refresh(profile)
    return _profile_out(profile)
@router.post("/delete-data", response_model=DeletionRequestOut)
async def request_data_deletion(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    db.add(DataDeletionRequest(user_id=current.id, email=current.email, status="done"))
    await db.execute(delete(Measurement).where(Measurement.user_id == current.id))
    await db.execute(delete(Alert).where(Alert.user_id == current.id))
    await db.execute(delete(ChatMessage).where(ChatMessage.user_id == current.id))
    await db.execute(delete(HealthProfile).where(HealthProfile.user_id == current.id))
    result = await db.execute(select(Device).where(Device.owner_id == current.id))
    for device in result.scalars().all():
        device.owner_id = None
        device.is_paired = False
    await db.commit()
    await resend_service.send_deletion_confirmation(current.email, current.full_name or "")
    return DeletionRequestOut(
        status="done",
        message="Tus datos han sido eliminados. Recibirás una confirmación por email.",
    )
def _profile_out(p: HealthProfile) -> HealthProfileOut:
    return HealthProfileOut(
        age=p.age,
        gender=p.gender,
        weight_kg=p.weight_kg,
        height_cm=p.height_cm,
        blood_type=p.blood_type,
        conditions=p.conditions,
        medications=p.medications,
        emergency_contact=p.emergency_contact,
        bmi=p.bmi,
        updated_at=p.updated_at,
    )