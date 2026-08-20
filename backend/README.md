# SpeciesTrace backend

## Overview

This backend is a FastAPI prototype for the SpeciesTrace forensic screening platform. It models the field evidence workflow, chain-of-custody events, device telemetry, field results, and laboratory handoff workflow.

## Key principles

- field result is presumptive only
- lab result is confirmatory and separate
- all sensitive actions require authorization
- audit trail is designed as append-only in concept

## Run locally

python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

## Demo accounts

- officer_id: DEMO-001
- password: demo1234

## Notes

This prototype intentionally does not claim scientific validation or legal finality. It models the operational architecture and workflow.
