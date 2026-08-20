# NEURAL PATROL — SPECIESTRACE

A portable field-deployable forensic screening prototype for presumptive species indication, digital evidence integrity, and FSL handoff. This project intentionally separates:

- FIELD RESULT = PRESUMPTIVE SCREENING
- FSL/LAB RESULT = FINAL CONFIRMATORY FORENSIC RESULT

## Modules

- backend: FastAPI API + SQLAlchemy models + SQLite local prototype database
- portal: React dashboard for FSL and case review
- mobile: Flutter app structure for SpeciesTrace
- firmware: ESP32 telemetry and process-state simulation
- cv: OpenCV-based strip validation concept and synthetic test image generator
- demo: data generation and integration script

## Verified status

The backend API smoke tests have passed with fresh local verification.

## Run backend

cd backend
python -m pip install -r requirements.txt
python -m pytest -q
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

## Run portal

cd portal
npm install
npm run build

## Run mobile app

cd mobile
flutter create .
flutter pub get
flutter run

See mobile/README.md for required camera/location permission setup and how to point the app at the backend (emulator, physical device, or fully offline demo mode).

## Notes

This prototype is intentionally designed as an operational workflow mockup and does not claim forensic accuracy or legal finality.
