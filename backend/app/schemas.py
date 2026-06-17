from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from app.models import DeviceMode, Gender
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = None
class UserLogin(BaseModel):
    email: EmailStr
    password: str
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
class EmailOnly(BaseModel):
    email: EmailStr
class VerifyRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=12)
class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=12)
    new_password: str = Field(min_length=8, max_length=128)
class MessageOut(BaseModel):
    message: str
class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: EmailStr
    full_name: str | None
    is_active: bool
    is_verified: bool
    created_at: datetime
class HealthProfileIn(BaseModel):
    age: int | None = Field(default=None, ge=0, le=130)
    gender: Gender | None = None
    weight_kg: float | None = Field(default=None, ge=0, le=500)
    height_cm: float | None = Field(default=None, ge=0, le=300)
    blood_type: str | None = None
    conditions: str | None = None
    medications: str | None = None
    emergency_contact: str | None = None
class HealthProfileOut(HealthProfileIn):
    model_config = ConfigDict(from_attributes=True)
    bmi: float | None = None
    updated_at: datetime | None = None
class DeviceProvision(BaseModel):
    device_uid: str = Field(min_length=4, max_length=64)
    name: str | None = None
class DeviceProvisionOut(BaseModel):
    device_uid: str
    api_key: str
    pairing_code: str
class DevicePair(BaseModel):
    pairing_code: str = Field(min_length=4, max_length=12)
    name: str | None = None
class DeviceConfigIn(BaseModel):
    name: str | None = None
    mode: DeviceMode | None = None
    sms_numbers: list[str] | None = None
class DeviceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    device_uid: str
    name: str
    is_paired: bool
    mode: DeviceMode
    sms_numbers: str | None
    last_seen: datetime | None
    created_at: datetime
class MeasurementIn(BaseModel):
    heart_rate: int = Field(ge=20, le=250)
    spo2: int = Field(ge=50, le=100)
    temperature: float = Field(ge=25, le=45)
    recorded_at: datetime | None = None
class MeasurementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    heart_rate: int
    spo2: int
    temperature: float
    status: str
    recorded_at: datetime
class IngestResult(BaseModel):
    measurement: MeasurementOut
    status: str
    summary: str
    recommendation: str
    alert_created: bool
class AlertOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    alert_type: str
    description: str
    severity: str
    created_at: datetime
class ChatIn(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
class ChatOut(BaseModel):
    reply: str
class RecommendationOut(BaseModel):
    recommendation: str
    based_on: int  
class DeletionRequestOut(BaseModel):
    status: str
    message: str