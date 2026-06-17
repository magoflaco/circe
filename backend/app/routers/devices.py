from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.deps import get_current_user, get_device_from_api_key
from app.models import Device, User
from app.schemas import (
    DeviceConfigIn,
    DeviceOut,
    DevicePair,
    DeviceProvision,
    DeviceProvisionOut,
)
from app.security import generate_api_key, generate_pairing_code
router = APIRouter(prefix="/api/v1/devices", tags=["devices"])
@router.post("/provision", response_model=DeviceProvisionOut)
async def provision(payload: DeviceProvision, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Device).where(Device.device_uid == payload.device_uid)
    )
    device = result.scalar_one_or_none()
    if device is None:
        device = Device(
            device_uid=payload.device_uid,
            name=payload.name or "Monitor Biomédico",
            api_key=generate_api_key(),
            pairing_code=generate_pairing_code(),
        )
        db.add(device)
    elif not device.is_paired:
        device.pairing_code = generate_pairing_code()  
    else:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Dispositivo ya vinculado. Desvincúlalo desde la app para reprovisionar.",
        )
    await db.commit()
    await db.refresh(device)
    return DeviceProvisionOut(
        device_uid=device.device_uid,
        api_key=device.api_key,
        pairing_code=device.pairing_code,
    )
@router.post("/pair", response_model=DeviceOut)
async def pair(
    payload: DevicePair,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Device).where(Device.pairing_code == payload.pairing_code.upper())
    )
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Código de vinculación inválido")
    if device.is_paired:
        raise HTTPException(status.HTTP_409_CONFLICT, "El dispositivo ya está vinculado")
    device.owner_id = current.id
    device.is_paired = True
    device.pairing_code = None
    if payload.name:
        device.name = payload.name
    await db.commit()
    await db.refresh(device)
    return device
@router.get("", response_model=list[DeviceOut])
async def list_devices(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Device).where(Device.owner_id == current.id))
    return list(result.scalars().all())
@router.put("/{device_id}/config", response_model=DeviceOut)
async def configure(
    device_id: int,
    payload: DeviceConfigIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    device = await db.get(Device, device_id)
    if not device or device.owner_id != current.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Dispositivo no encontrado")
    if payload.name is not None:
        device.name = payload.name
    if payload.mode is not None:
        device.mode = payload.mode
    if payload.sms_numbers is not None:
        device.sms_numbers = ",".join(payload.sms_numbers)
    await db.commit()
    await db.refresh(device)
    return device
@router.delete("/{device_id}", status_code=204)
async def unpair(
    device_id: int,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    device = await db.get(Device, device_id)
    if not device or device.owner_id != current.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Dispositivo no encontrado")
    device.owner_id = None
    device.is_paired = False
    await db.commit()
@router.get("/config/remote", response_model=DeviceConfigIn)
async def get_remote_config(device: Device = Depends(get_device_from_api_key)):
    return DeviceConfigIn(
        name=device.name,
        mode=device.mode,
        sms_numbers=device.sms_numbers.split(",") if device.sms_numbers else [],
    )