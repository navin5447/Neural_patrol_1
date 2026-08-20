from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    officer_id = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    role = Column(String, nullable=False, default="field_officer")
    password_hash = Column(String, nullable=False)
    status = Column(String, default="active")
    created_at = Column(DateTime, default=datetime.utcnow)


class Case(Base):
    __tablename__ = "cases"

    id = Column(Integer, primary_key=True, index=True)
    case_number = Column(String, unique=True, index=True, nullable=False)
    title = Column(String, nullable=True)
    location = Column(String, nullable=True)
    created_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Sample(Base):
    __tablename__ = "samples"

    id = Column(Integer, primary_key=True, index=True)
    case_id = Column(Integer, ForeignKey("cases.id"), nullable=False)
    sample_code = Column(String, unique=True, index=True, nullable=False)
    sample_type = Column(String, nullable=False)
    location = Column(String, nullable=True)
    officer_name = Column(String, nullable=True)
    date = Column(String, nullable=True)
    time = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    gps_lat = Column(Float, nullable=True)
    gps_lon = Column(Float, nullable=True)
    device_id = Column(String, nullable=True)
    operator_id = Column(String, nullable=True)
    sealed_status = Column(Boolean, default=False)
    preserved_status = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    device_name = Column(String, nullable=False)
    serial_number = Column(String, unique=True, nullable=False)
    hw_version = Column(String, nullable=True)
    status = Column(String, default="connected")
    last_seen_at = Column(DateTime, default=datetime.utcnow)
    public_key_id = Column(String, nullable=True)


class TestRun(Base):
    __tablename__ = "test_runs"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    device_id = Column(Integer, ForeignKey("devices.id"), nullable=False)
    assay_profile_id = Column(String, nullable=True)
    status = Column(String, default="started")
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    run_metadata = Column(Text, nullable=True)


class FieldResult(Base):
    __tablename__ = "field_results"

    id = Column(Integer, primary_key=True, index=True)
    test_run_id = Column(Integer, ForeignKey("test_runs.id"), nullable=False)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    status = Column(String, nullable=False, default="presumptive")
    target_indication = Column(String, nullable=True)
    control_valid = Column(Boolean, default=False)
    quality_score = Column(Float, default=0.0)
    image_ref = Column(String, nullable=True)
    raw_result_payload = Column(Text, nullable=True)
    recorded_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    previous_record_hash = Column(String, nullable=True)
    current_record_hash = Column(String, nullable=True)


class EvidenceImage(Base):
    __tablename__ = "evidence_images"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    test_run_id = Column(Integer, ForeignKey("test_runs.id"), nullable=False)
    storage_uri = Column(String, nullable=False)
    image_hash = Column(String, nullable=False)
    image_metadata = Column(Text, nullable=True)
    captured_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    captured_at = Column(DateTime, default=datetime.utcnow)


class CustodyEvent(Base):
    __tablename__ = "custody_events"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    event_type = Column(String, nullable=False)
    who_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    what_action = Column(String, nullable=False)
    when_ts = Column(DateTime, default=datetime.utcnow)
    where_location = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    previous_hash = Column(String, nullable=True)
    current_hash = Column(String, nullable=True)
    is_immutable = Column(Boolean, default=True)


class FslHandoff(Base):
    __tablename__ = "fsl_handoffs"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    destination_lab = Column(String, nullable=False)
    field_status = Column(String, default="presumptive_result_recorded")
    physical_sample_status = Column(String, default="sealed_for_confirmation")
    qr_code_value = Column(String, nullable=False)
    dispatched_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    dispatched_at = Column(DateTime, default=datetime.utcnow)
    receiving_acknowledged_at = Column(DateTime, nullable=True)


class LabResult(Base):
    __tablename__ = "lab_results"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    confirmatory_method = Column(String, nullable=True)
    confirmatory_result = Column(String, nullable=True)
    analyst_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    result_document_uri = Column(String, nullable=True)
    signed_at = Column(DateTime, nullable=True)
    previous_hash = Column(String, nullable=True)
    current_hash = Column(String, nullable=True)
    status = Column(String, default="recorded")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    sample_id = Column(Integer, ForeignKey("samples.id"), nullable=False)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    action = Column(String, nullable=False)
    actor_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    summary = Column(Text, nullable=True)
    previous_hash = Column(String, nullable=True)
    current_hash = Column(String, nullable=True)
