import hashlib
from datetime import datetime

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import Base, SessionLocal, engine, get_db
from app import models, schemas
from app.demo_seed import seed_demo_data
from app.security import create_access_token, decode_access_token, hash_password, verify_password

Base.metadata.create_all(bind=engine)
seed_demo_data()

app = FastAPI(title="SpeciesTrace API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    officer_id = payload.get("sub")
    user = db.query(models.User).filter(models.User.officer_id == officer_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user


@app.post("/auth/login", response_model=dict)
def login(payload: dict, db: Session = Depends(get_db)):
    officer_id = str(payload.get("officer_id", "")).strip()
    password = str(payload.get("password", ""))
    if not officer_id or not password:
        raise HTTPException(status_code=400, detail="Officer ID and password are required")

    user = db.query(models.User).filter(models.User.officer_id == officer_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(subject=user.officer_id)
    return {"access_token": token, "token_type": "bearer"}


@app.post("/auth/demo-login", response_model=dict)
def demo_login(db: Session = Depends(get_db)):
    demo_user = db.query(models.User).filter(models.User.officer_id == "DEMO-001").first()
    if demo_user is None:
        demo_user = models.User(
            officer_id="DEMO-001",
            name="Demo Officer",
            role="field_officer",
            password_hash=hash_password("demo1234"),
            status="active",
        )
        db.add(demo_user)
        db.commit()
        db.refresh(demo_user)

    token = create_access_token(subject=demo_user.officer_id)
    return {"access_token": token, "token_type": "bearer"}


@app.get("/me")
def get_me(user: models.User = Depends(get_current_user)):
    return {
        "id": user.id,
        "officer_id": user.officer_id,
        "name": user.name,
        "role": user.role,
        "status": user.status,
    }


@app.post("/cases")
def create_case(payload: schemas.CaseCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    case = models.Case(**payload.model_dump(), created_by_user_id=user.id)
    db.add(case)
    db.commit()
    db.refresh(case)
    return case


@app.get("/cases")
def list_cases(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return db.query(models.Case).order_by(models.Case.created_at.desc()).limit(200).all()


@app.get("/cases/{case_id}")
def get_case(case_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    case = db.query(models.Case).filter(models.Case.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    return case


@app.post("/samples")
def create_sample(payload: schemas.SampleCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    existing_count = db.query(models.Sample).filter(models.Sample.case_id == payload.case_id).count()
    loc_tag = "".join(ch for ch in (payload.location or "CHD").upper() if ch.isalnum())[:4] or "CHD"
    sample_code = f"NP-{loc_tag}-{payload.case_id:04d}-{existing_count + 1:03d}"
    sample = models.Sample(
        case_id=payload.case_id,
        sample_code=sample_code,
        sample_type=payload.sample_type,
        location=payload.location,
        officer_name=payload.officer_name,
        date=payload.date,
        time=payload.time,
        notes=payload.notes,
        gps_lat=payload.gps_lat,
        gps_lon=payload.gps_lon,
        device_id=payload.device_id,
        operator_id=payload.operator_id,
    )
    db.add(sample)
    db.commit()
    db.refresh(sample)
    _append_audit(db, sample.id, "sample", sample.id, "sample_registered", user.id, sample.sample_code)
    db.refresh(sample)
    return sample


@app.get("/samples")
def list_samples(case_id: int | None = None, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    query = db.query(models.Sample)
    if case_id is not None:
        query = query.filter(models.Sample.case_id == case_id)
    return query.order_by(models.Sample.created_at.desc()).limit(200).all()


@app.get("/samples/{sample_id}")
def get_sample(sample_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    sample = db.query(models.Sample).filter(models.Sample.id == sample_id).first()
    if not sample:
        raise HTTPException(status_code=404, detail="Sample not found")
    return sample


@app.post("/samples/{sample_id}/custody-events")
def add_custody_event(sample_id: int, payload: schemas.CustodyEventCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    if sample_id != payload.sample_id:
        raise HTTPException(status_code=400, detail="Sample ID mismatch")
    previous = (
        db.query(models.CustodyEvent)
        .filter(models.CustodyEvent.sample_id == sample_id)
        .order_by(models.CustodyEvent.id.desc())
        .first()
    )
    previous_hash = previous.current_hash if previous else "GENESIS"
    digest_source = f"{previous_hash}|{sample_id}|{payload.event_type}|{payload.what_action}|{payload.who_user_id}"
    current_hash = hashlib.sha256(digest_source.encode("utf-8")).hexdigest()
    event = models.CustodyEvent(
        **payload.model_dump(),
        previous_hash=previous_hash,
        current_hash=current_hash,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    _append_audit(db, sample_id, "custody_event", event.id, payload.event_type, payload.who_user_id, payload.what_action)
    db.refresh(event)
    return event


@app.get("/samples/{sample_id}/custody-events")
def list_custody_events(sample_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.CustodyEvent)
        .filter(models.CustodyEvent.sample_id == sample_id)
        .order_by(models.CustodyEvent.id.asc())
        .all()
    )


@app.post("/devices/connect")
def register_device(payload: schemas.DeviceCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    existing = db.query(models.Device).filter(models.Device.serial_number == payload.serial_number).first()
    if existing:
        existing.status = "connected"
        existing.last_seen_at = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return existing
    device = models.Device(**payload.model_dump())
    db.add(device)
    db.commit()
    db.refresh(device)
    return device


@app.get("/devices")
def list_devices(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return db.query(models.Device).order_by(models.Device.last_seen_at.desc()).limit(200).all()


@app.post("/test-runs")
def create_test_run(payload: schemas.TestRunCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    run = models.TestRun(**payload.model_dump())
    db.add(run)
    db.commit()
    db.refresh(run)
    return run


@app.post("/test-runs/{id}/telemetry")
def telemetry(id: int, payload: dict, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    run = db.query(models.TestRun).filter(models.TestRun.id == id).first()
    if not run:
        raise HTTPException(status_code=404, detail="Test run not found")
    return {"run_id": id, "telemetry": payload}


def _append_audit(db: Session, sample_id: int, entity_type: str, entity_id: int, action: str, actor_user_id: int, summary: str | None = None):
    previous = (
        db.query(models.AuditLog)
        .filter(models.AuditLog.sample_id == sample_id)
        .order_by(models.AuditLog.id.desc())
        .first()
    )
    previous_hash = previous.current_hash if previous else "GENESIS"
    digest_source = f"{previous_hash}|{sample_id}|{entity_type}|{entity_id}|{action}|{actor_user_id}"
    current_hash = hashlib.sha256(digest_source.encode("utf-8")).hexdigest()
    log = models.AuditLog(
        sample_id=sample_id,
        entity_type=entity_type,
        entity_id=entity_id,
        action=action,
        actor_user_id=actor_user_id,
        summary=summary,
        previous_hash=previous_hash,
        current_hash=current_hash,
    )
    db.add(log)
    db.commit()


@app.post("/field-results")
def create_field_result(payload: schemas.FieldResultCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    previous = (
        db.query(models.FieldResult)
        .filter(models.FieldResult.sample_id == payload.sample_id)
        .order_by(models.FieldResult.id.desc())
        .first()
    )
    previous_hash = previous.current_record_hash if previous else "GENESIS"
    digest_source = f"{previous_hash}|{payload.sample_id}|{payload.test_run_id}|{payload.target_indication}|{payload.control_valid}"
    current_hash = hashlib.sha256(digest_source.encode("utf-8")).hexdigest()
    result = models.FieldResult(
        **payload.model_dump(),
        previous_record_hash=previous_hash,
        current_record_hash=current_hash,
    )
    db.add(result)
    db.commit()
    db.refresh(result)
    _append_audit(db, payload.sample_id, "field_result", result.id, "field_result_recorded", user.id, payload.target_indication)
    db.refresh(result)
    return result


@app.get("/samples/{sample_id}/field-results")
def list_field_results(sample_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.FieldResult)
        .filter(models.FieldResult.sample_id == sample_id)
        .order_by(models.FieldResult.id.desc())
        .all()
    )


@app.post("/evidence-images")
def create_evidence_image(payload: schemas.EvidenceImageCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    image = models.EvidenceImage(**payload.model_dump())
    db.add(image)
    db.commit()
    db.refresh(image)
    return image


@app.post("/fsl-handoffs")
def create_fsl_handoff(payload: schemas.FslHandoffCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    handoff = models.FslHandoff(**payload.model_dump())
    db.add(handoff)
    db.commit()
    db.refresh(handoff)
    _append_audit(db, payload.sample_id, "fsl_handoff", handoff.id, "dispatched_to_fsl", user.id, payload.destination_lab)
    db.refresh(handoff)
    return handoff


@app.get("/samples/{sample_id}/fsl-handoffs")
def list_fsl_handoffs(sample_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.FslHandoff)
        .filter(models.FslHandoff.sample_id == sample_id)
        .order_by(models.FslHandoff.id.desc())
        .all()
    )


@app.post("/lab-results")
def create_lab_result(payload: schemas.LabResultCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    result = models.LabResult(**payload.model_dump())
    db.add(result)
    db.commit()
    db.refresh(result)
    return result


@app.get("/audit/{sample_id}")
def get_audit(sample_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    logs = db.query(models.AuditLog).filter(models.AuditLog.sample_id == sample_id).all()
    return logs


@app.get("/case-summary/{case_id}")
def get_case_summary(case_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    case = db.query(models.Case).filter(models.Case.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    samples = db.query(models.Sample).filter(models.Sample.case_id == case_id).all()
    return {"case": case, "samples": samples, "sample_count": len(samples)}


@app.get("/dashboard/summary")
def get_dashboard_summary(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    today = datetime.utcnow().strftime("%Y-%m-%d")
    active_cases = db.query(models.Case).count()
    todays_samples = db.query(models.Sample).filter(models.Sample.date == today).count()
    dispatched_handoffs = {h.sample_id for h in db.query(models.FslHandoff).all()}
    lab_confirmed = {r.sample_id for r in db.query(models.LabResult).all()}
    pending_fsl = len(dispatched_handoffs - lab_confirmed)
    field_results_count = db.query(models.FieldResult).count()
    return {
        "active_cases": active_cases,
        "todays_samples": todays_samples,
        "pending_fsl": pending_fsl,
        "field_results_count": field_results_count,
    }


@app.get("/")
def root():
    return {"message": "SpeciesTrace API is operational."}
