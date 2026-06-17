from __future__ import annotations
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app import health_rules
from app.database import AsyncSessionLocal, get_db
from app.deps import get_current_user, get_device_from_api_key
from app.models import Alert, Device, Measurement, User, utcnow
from app.realtime import manager
from app.schemas import IngestResult, MeasurementIn, MeasurementOut
from app.security import decode_token
router = APIRouter(prefix="/api/v1", tags=["measurements"])
@router.post("/ingest", response_model=IngestResult)
async def ingest(
    payload: MeasurementIn,
    device: Device = Depends(get_device_from_api_key),
    db: AsyncSession = Depends(get_db),
):
    ev = health_rules.evaluate(payload.heart_rate, payload.spo2, payload.temperature)
    measurement = Measurement(
        user_id=device.owner_id,
        device_id=device.id,
        heart_rate=payload.heart_rate,
        spo2=payload.spo2,
        temperature=payload.temperature,
        status=ev.status,
        recorded_at=payload.recorded_at or utcnow(),
    )
    db.add(measurement)
    device.last_seen = utcnow()
    alert_created = False
    if ev.status == "Alerta":
        db.add(
            Alert(
                user_id=device.owner_id,
                alert_type="Anomalía en signos vitales",
                description=ev.summary + " " + ev.recommendation,
                severity=ev.severity,
            )
        )
        alert_created = True
    await db.commit()
    await db.refresh(measurement)
    if device.owner_id:
        await manager.send_to_user(
            device.owner_id,
            {
                "type": "measurement",
                "data": {
                    "id": measurement.id,
                    "heart_rate": measurement.heart_rate,
                    "spo2": measurement.spo2,
                    "temperature": measurement.temperature,
                    "status": measurement.status,
                    "recorded_at": measurement.recorded_at.isoformat(),
                    "summary": ev.summary,
                },
            },
        )
    return IngestResult(
        measurement=MeasurementOut.model_validate(measurement),
        status=ev.status,
        summary=ev.summary,
        recommendation=ev.recommendation,
        alert_created=alert_created,
    )
@router.get("/measurements", response_model=list[MeasurementOut])
async def list_measurements(
    limit: int = Query(50, ge=1, le=500),
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Measurement)
        .where(Measurement.user_id == current.id)
        .order_by(Measurement.recorded_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())
@router.get("/measurements/latest", response_model=MeasurementOut | None)
async def latest_measurement(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Measurement)
        .where(Measurement.user_id == current.id)
        .order_by(Measurement.recorded_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()
@router.websocket("/ws/measurements")
async def measurements_ws(websocket: WebSocket, token: str = Query(...)):
    payload = decode_token(token)
    if not payload or "sub" not in payload:
        await websocket.close(code=4401)
        return
    user_id = int(payload["sub"])
    async with AsyncSessionLocal() as db:
        user = await db.get(User, user_id)
        if not user:
            await websocket.close(code=4401)
            return
    await manager.connect(user_id, websocket)
    try:
        while True:
            await websocket.receive_text()  
    except WebSocketDisconnect:
        await manager.disconnect(user_id, websocket)