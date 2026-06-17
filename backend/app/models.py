from __future__ import annotations
import enum
from datetime import datetime, timezone
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
def utcnow() -> datetime:
    return datetime.now(timezone.utc)
class Gender(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"
    unspecified = "unspecified"
class DeviceMode(str, enum.Enum):
    wifi = "wifi"
    gprs = "gprs"
class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verification_code: Mapped[str | None] = mapped_column(String(12), nullable=True)
    reset_code: Mapped[str | None] = mapped_column(String(12), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    profile: Mapped[HealthProfile | None] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    devices: Mapped[list[Device]] = relationship(
        back_populates="owner", cascade="all, delete-orphan"
    )
    measurements: Mapped[list[Measurement]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    alerts: Mapped[list[Alert]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    chat_messages: Mapped[list[ChatMessage]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
class HealthProfile(Base):
    __tablename__ = "health_profiles"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    gender: Mapped[Gender] = mapped_column(Enum(Gender), default=Gender.unspecified)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    blood_type: Mapped[str | None] = mapped_column(String(8), nullable=True)
    conditions: Mapped[str | None] = mapped_column(Text, nullable=True)  
    medications: Mapped[str | None] = mapped_column(Text, nullable=True)
    emergency_contact: Mapped[str | None] = mapped_column(String(120), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )
    user: Mapped[User] = relationship(back_populates="profile")
    @property
    def bmi(self) -> float | None:
        if self.weight_kg and self.height_cm:
            h = self.height_cm / 100
            return round(self.weight_kg / (h * h), 1)
        return None
class Device(Base):
    __tablename__ = "devices"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    device_uid: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(80), default="Monitor Biomédico")
    api_key: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    pairing_code: Mapped[str | None] = mapped_column(String(12), nullable=True, index=True)
    is_paired: Mapped[bool] = mapped_column(Boolean, default=False)
    owner_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=True
    )
    mode: Mapped[DeviceMode] = mapped_column(Enum(DeviceMode), default=DeviceMode.wifi)
    sms_numbers: Mapped[str | None] = mapped_column(String(255), nullable=True)  
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    owner: Mapped[User | None] = relationship(back_populates="devices")
    measurements: Mapped[list[Measurement]] = relationship(
        back_populates="device", cascade="all, delete-orphan"
    )
class Measurement(Base):
    __tablename__ = "measurements"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True
    )
    device_id: Mapped[int | None] = mapped_column(
        ForeignKey("devices.id", ondelete="CASCADE"), nullable=True, index=True
    )
    heart_rate: Mapped[int] = mapped_column(Integer)
    spo2: Mapped[int] = mapped_column(Integer)
    temperature: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(20), default="Normal")  
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    user: Mapped[User | None] = relationship(back_populates="measurements")
    device: Mapped[Device | None] = relationship(back_populates="measurements")
class Alert(Base):
    __tablename__ = "alerts"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True
    )
    measurement_id: Mapped[int | None] = mapped_column(
        ForeignKey("measurements.id", ondelete="SET NULL"), nullable=True
    )
    alert_type: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text)
    severity: Mapped[str] = mapped_column(String(20), default="warning")  
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    user: Mapped[User | None] = relationship(back_populates="alerts")
class ChatMessage(Base):
    __tablename__ = "chat_messages"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(16))  
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    user: Mapped[User] = relationship(back_populates="chat_messages")
class DataDeletionRequest(Base):
    __tablename__ = "data_deletion_requests"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, index=True)
    email: Mapped[str] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(20), default="pending")  
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)