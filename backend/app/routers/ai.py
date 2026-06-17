from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.deps import get_current_user
from app.models import ChatMessage, HealthProfile, Measurement, User
from app.schemas import ChatIn, ChatOut, RecommendationOut
from app.services import analysis, groq_service
router = APIRouter(prefix="/api/v1/ai", tags=["ai"])
async def _profile_context(db: AsyncSession, user: User) -> str:
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    p = result.scalar_one_or_none()
    if not p:
        return "Sin perfil de salud."
    parts = []
    if p.age:
        parts.append(f"edad {p.age}")
    if p.gender:
        parts.append(f"género {p.gender.value}")
    if p.weight_kg:
        parts.append(f"peso {p.weight_kg} kg")
    if p.height_cm:
        parts.append(f"altura {p.height_cm} cm")
    if p.bmi:
        parts.append(f"IMC {p.bmi}")
    if p.conditions:
        parts.append(f"condiciones: {p.conditions}")
    if p.medications:
        parts.append(f"medicación: {p.medications}")
    return ", ".join(parts) if parts else "Perfil incompleto."
@router.get("/recommendation", response_model=RecommendationOut)
async def get_recommendation(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Measurement)
        .where(Measurement.user_id == current.id)
        .order_by(Measurement.recorded_at.desc())
        .limit(50)
    )
    measurements = list(result.scalars().all())
    vitals = analysis.summary_text(measurements)
    profile = await _profile_context(db, current)
    try:
        text = await groq_service.recommendation(profile, vitals)
    except groq_service.GroqUnavailable:
        text = _fallback_recommendation(measurements)
    return RecommendationOut(recommendation=text, based_on=len(measurements))
@router.post("/suggest", response_model=ChatOut)
async def suggest(
    payload: ChatIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _profile_context(db, current)
    try:
        reply = await groq_service.chat([], payload.message, profile)
    except groq_service.GroqUnavailable:
        reply = ("Mantén un ritmo activo y constante a lo largo del día. "
                 "Pequeñas caminatas frecuentes suman mucho. ¡Cada paso cuenta!")
    return ChatOut(reply=reply)
@router.post("/chat", response_model=ChatOut)
async def chat(
    payload: ChatIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.user_id == current.id)
        .order_by(ChatMessage.created_at.desc())
        .limit(10)
    )
    history_rows = list(reversed(result.scalars().all()))
    history = [{"role": m.role, "content": m.content} for m in history_rows]
    profile = await _profile_context(db, current)
    try:
        reply = await groq_service.chat(history, payload.message, profile)
    except groq_service.GroqUnavailable:
        raise HTTPException(503, "El chat de IA no está configurado (falta GROQ_API_KEY)")
    db.add(ChatMessage(user_id=current.id, role="user", content=payload.message))
    db.add(ChatMessage(user_id=current.id, role="assistant", content=reply))
    await db.commit()
    return ChatOut(reply=reply)
@router.get("/chat/history", response_model=list[dict])
async def chat_history(
    current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.user_id == current.id)
        .order_by(ChatMessage.created_at.asc())
        .limit(100)
    )
    return [
        {"role": m.role, "content": m.content, "created_at": m.created_at.isoformat()}
        for m in result.scalars().all()
    ]
def _fallback_recommendation(measurements: list[Measurement]) -> str:
    s = analysis.summarize(measurements)
    if s["count"] == 0:
        return "Aún no hay mediciones. Conecta tu dispositivo para empezar a monitorear."
    if s["alerts"] == 0:
        return (
            "Tus signos vitales se mantienen en rangos normales. Continúa con tus "
            "hábitos saludables, hidrátate y mantén actividad física moderada."
        )
    return (
        f"Se detectaron {s['alerts']} mediciones con anomalías. Procura descansar, "
        "evita esfuerzos intensos y vigila tus síntomas. Si persisten o empeoran, "
        "consulta a un profesional de la salud."
    )