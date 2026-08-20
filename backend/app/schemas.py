from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    officer_id: str
    name: str
    role: str = "field_officer"
    password: str


class UserOut(BaseModel):
    id: int
    officer_id: str
    name: str
    role: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CaseCreate(BaseModel):
    case_number: str
    title: Optional[str] = None
    location: Optional[str] = None


class SampleCreate(BaseModel):
    case_id: int
    sample_type: str
    location: Optional[str] = None
    officer_name: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    notes: Optional[str] = None
    gps_lat: Optional[float] = None
    gps_lon: Optional[float] = None
    device_id: Optional[str] = None
    operator_id: Optional[str] = None


class DeviceCreate(BaseModel):
    device_name: str
    serial_number: str
    hw_version: Optional[str] = None


class TestRunCreate(BaseModel):
    sample_id: int
    device_id: int
    assay_profile_id: Optional[str] = "research_validation_dependent"
    run_metadata: Optional[str] = None


class FieldResultCreate(BaseModel):
    test_run_id: int
    sample_id: int
    status: str = "presumptive"
    target_indication: Optional[str] = None
    control_valid: bool = False
    quality_score: float = 0.0
    image_ref: Optional[str] = None
    raw_result_payload: Optional[str] = None
    recorded_by_user_id: int


class EvidenceImageCreate(BaseModel):
    sample_id: int
    test_run_id: int
    storage_uri: str
    image_hash: str
    image_metadata: Optional[str] = None
    captured_by_user_id: int


class CustodyEventCreate(BaseModel):
    sample_id: int
    event_type: str
    who_user_id: int
    what_action: str
    where_location: Optional[str] = None
    notes: Optional[str] = None


class FslHandoffCreate(BaseModel):
    sample_id: int
    destination_lab: str = "AUTHORIZED FSL"
    field_status: str = "presumptive_result_recorded"
    physical_sample_status: str = "sealed_for_confirmation"
    qr_code_value: str
    dispatched_by_user_id: int


class LabResultCreate(BaseModel):
    sample_id: int
    confirmatory_method: Optional[str] = None
    confirmatory_result: Optional[str] = None
    analyst_user_id: int
    result_document_uri: Optional[str] = None
    status: str = "recorded"


class AuditLogCreate(BaseModel):
    sample_id: int
    entity_type: str
    entity_id: int
    action: str
    actor_user_id: int
    summary: Optional[str] = None
