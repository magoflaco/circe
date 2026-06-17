from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.deps import get_current_user
from app.models import HealthProfile, User
from app.schemas import (
    EmailOnly,
    MessageOut,
    ResetPasswordRequest,
    Token,
    UserCreate,
    UserLogin,
    UserOut,
    VerifyRequest,
)
from app.security import (
    create_access_token,
    generate_numeric_code,
    hash_password,
    verify_password,
)
from app.services import resend_service
router = APIRouter(prefix="/api/v1/auth", tags=["auth"])
@router.post("/register", response_model=Token, status_code=201)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    exists = await db.execute(select(User).where(User.email == payload.email))
    if exists.scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "El email ya está registrado")
    code = generate_numeric_code()
    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        verification_code=code,
    )
    user.profile = HealthProfile()
    db.add(user)
    await db.commit()
    await db.refresh(user)
    await resend_service.send_verification_email(user.email, user.full_name or "", code)
    return Token(access_token=create_access_token(user.id))
@router.post("/login", response_model=Token)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Email o contraseña incorrectos")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cuenta desactivada")
    return Token(access_token=create_access_token(user.id))
@router.post("/verify", response_model=UserOut)
async def verify(payload: VerifyRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not user.verification_code or user.verification_code != payload.code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Código inválido o expirado")
    user.is_verified = True
    user.verification_code = None
    await db.commit()
    await db.refresh(user)
    await resend_service.send_welcome_email(user.email, user.full_name or "")
    return user
@router.post("/resend-code", response_model=MessageOut)
async def resend_code(payload: EmailOnly, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if user and not user.is_verified:
        code = generate_numeric_code()
        user.verification_code = code
        await db.commit()
        await resend_service.send_verification_email(user.email, user.full_name or "", code)
    return MessageOut(message="Si el correo existe y no está verificado, enviamos un nuevo código.")
@router.post("/forgot-password", response_model=MessageOut)
async def forgot_password(payload: EmailOnly, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if user:
        code = generate_numeric_code()
        user.reset_code = code
        await db.commit()
        await resend_service.send_reset_email(user.email, user.full_name or "", code)
    return MessageOut(message="Si el correo existe, te enviamos un código para restablecer la contraseña.")
@router.post("/reset-password", response_model=Token)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not user.reset_code or user.reset_code != payload.code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Código inválido o expirado")
    user.hashed_password = hash_password(payload.new_password)
    user.reset_code = None
    await db.commit()
    await db.refresh(user)
    return Token(access_token=create_access_token(user.id))
@router.get("/me", response_model=UserOut)
async def me(current: User = Depends(get_current_user)):
    return current