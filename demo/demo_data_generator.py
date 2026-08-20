import json
from datetime import datetime, timedelta


def build_demo_case():
    now = datetime.utcnow()
    return {
        "case": {
            "case_number": "CHD-2026-041",
            "title": "Suspected species substitution",
            "location": "Chandigarh",
            "created_at": now.isoformat(),
        },
        "sample": {
            "sample_id": "NP-CHD-2026-000128",
            "sample_type": "meat tissue",
            "location": "Seizure point A",
            "officer_name": "Officer A. Mehta",
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M"),
            "notes": "Seized biological evidence retained for screening and FSL handoff.",
            "gps_lat": 30.7333,
            "gps_lon": 76.7794,
        },
        "custody_events": [
            {"time": (now - timedelta(minutes=15)).strftime("%H:%M"), "event": "SAMPLE REGISTERED"},
            {"time": (now - timedelta(minutes=12)).strftime("%H:%M"), "event": "SEALED AND PACKAGED"},
            {"time": (now - timedelta(minutes=10)).strftime("%H:%M"), "event": "FIELD TEST STARTED"},
            {"time": (now - timedelta(minutes=2)).strftime("%H:%M"), "event": "FIELD RESULT RECORDED"},
            {"time": now.strftime("%H:%M"), "event": "CONFIRMATORY SAMPLE DISPATCHED"},
        ],
        "field_result": {
            "status": "PRESUMPTIVE FIELD RESULT",
            "target": "BUFFALO DETECTED",
            "quality_score": 0.92,
            "control_valid": True,
        },
        "lab_result": {
            "status": "CONFIRMATORY LAB RESULT",
            "target": "BUFFALO",
            "method": "authorized confirmatory method",
        },
    }


if __name__ == "__main__":
    data = build_demo_case()
    print(json.dumps(data, indent=2))
