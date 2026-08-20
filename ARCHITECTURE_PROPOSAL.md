# NEURAL PATROL — SPECIESTRACE

## Project framing

This prototype is intentionally designed as a field-first presumptive screening platform. It does not replace laboratory forensic confirmation. It exists to reduce the time between seizure and the first scientifically informed field signal while preserving evidentiary integrity and maintaining a digital chain of custody.

Operational distinction:

- FIELD RESULT = PRESUMPTIVE SCREENING
- FSL/LAB RESULT = FINAL CONFIRMATORY FORENSIC RESULT

The field result must never be presented as legal proof or final forensic confirmation.

---

## 1. Complete system architecture diagram in text

    PHYSICAL EVIDENCE
            ↓
    SECURE SAMPLE COLLECTION
            ↓
    QR / BARCODE IDENTITY
            ↓
    FIELD DEVICE (portable isothermal assay platform)
            ↓
    SAMPLE PREPARATION / DNA RELEASE
            ↓
    CONTROLLED ISOTHERMAL AMPLIFICATION
            ↓
    DETECTION STRIP / INSTRUMENT READOUT
            ↓
    SMARTPHONE APP (SpeciesTrace)
            ↓
    COMPUTER VISION VALIDATION
            ↓
    PRESUMPTIVE FIELD RESULT
            ↓
    DIGITAL CHAIN OF CUSTODY + IMAGE HASH + EVENT HASH
            ↓
    ORIGINAL SAMPLE PRESERVED
            ↓
    AUTHORIZED FSL / LABORATORY
            ↓
    CONFIRMATORY LAB RESULT
            ↓
    CASE RECORD + FINAL FORENSIC REPORT

System layers:

    LAYER A: PORTABLE FIELD HARDWARE
        - rugged device
        - thermal control
        - cartridge holder
        - temperature telemetry
        - BLE communication

    LAYER B: DISPOSABLE TEST WORKFLOW
        - sachet / cartridge / reaction system
        - sample prep and reagent handling
        - assay configuration profile
        - control region and detection zones

    LAYER C: MOBILE APPLICATION
        - secure login
        - case and sample registration
        - offline evidence capture
        - CV validation
        - field result recording
        - chain-of-custody ledger

    LAYER D: FORENSIC CASE MANAGEMENT + FSL PORTAL
        - FSL intake
        - evidence handoff
        - confirmatory method entry
        - lab result signing
        - case closure

---

## 2. Hardware block diagram

    +------------------------------------------------------------+
    |                    PORTABLE FIELD UNIT                      |
    |                                                            |
    |  +-----------------+   +-------------------------------+    |
    |  | Power system   |   | Control system               |    |
    |  | - Li-ion bat.  |   | - MCU / SoC                 |    |
    |  | - BMS          |   | - temp sensor               |    |
    |  | - USB-C chg    |   | - heater driver             |    |
    |  | - 5V/3.3V rails|   | - safety cut-off            |    |
    |  +-----------------+   | - BLE / Wi-Fi comms         |    |
    |                           +-------------------------------+    |
    |                                                            |
    |  +-----------------+   +-------------------------------+    |
    |  | Thermal system |   | User feedback / IO           |    |
    |  | - heating block|   | - display                   |    |
    |  | - cartridge    |   | - status LED                |    |
    |  | - PID control  |   | - buzzer                    |    |
    |  | - thermal cut  |   | - buttons                   |    |
    |  +-----------------+   +-------------------------------+    |
    |                                                            |
    |  +--------------------------------------------------------+  |
    |  | Sealed reaction chamber / tube cartridge holder       |  |
    |  +--------------------------------------------------------+  |
    +------------------------------------------------------------+
                             │
                             │ BLE / secure sync
                             ▼
                  +-------------------------------+
                  | SpeciesTrace mobile app      |
                  | Android-first field workflow  |
                  +-------------------------------+

### Product concept

- rugged, compact, suitable for forensic vehicle or field kit
- splash-resistant enclosure with sealed assay chamber
- rechargeable battery with protected power rails
- microcontroller-based thermal control and telemetry
- modular cartridge interface to support future authorized assay modules
- display showing status, temperature, sample ID, and process mode

### Hardware signal states

- READY
- PREHEAT
- RUNNING
- VALIDATION
- COMPLETE
- ERROR
- SAFETY SHUTDOWN

### Important design note

This hardware is for controlled isothermal molecular workflow support and detection readout. It is not presented as a stand-alone species identification device for legal conclusions.

---

## 3. Software architecture

    +-----------------------------------------------------------+
    | Mobile app: SpeciesTrace                                  |
    |-----------------------------------------------------------|
    | UI Layer                                                  |
    | - secure login                                             |
    | - dashboard                                               |
    | - create sample                                            |
    | - custody timeline                                        |
    | - device connection                                        |
    | - result capture                                           |
    | - field result                                             |
    | - evidence record                                         |
    | - FSL handoff                                             |
    +-------------------------------+---------------------------+
                                    │
                                    ▼
    +-----------------------------------------------------------+
    | Domain / Use-case services                                  |
    | - case management                                          |
    | - sample lifecycle                                         |
    | - custody event ledger                                     |
    | - device handling                                          |
    | - test run orchestration                                   |
    | - field result workflows                                   |
    | - FSL handoff workflow                                     |
    | - offline queue manager                                    |
    +-------------------------------+---------------------------+
                                    │
                                    ▼
    +-----------------------------------------------------------+
    | Data / security services                                    |
    | - encrypted local storage                                  |
    | - SQLite cache                                             |
    | - secure token store                                       |
    | - image hashing                                            |
    | - record hashing                                           |
    | - audit log generation                                     |
    | - checksum validation                                      |
    +-------------------------------+---------------------------+
                                    │
                                    ▼
    +-----------------------------------------------------------+
    | Device integration                                         |
    | - BLE telemetry                                             |
    | - device status streaming                                   |
    | - process state transfer                                    |
    | - result submission                                         |
    +-------------------------------+---------------------------+
                                    │
                                    ▼
    +-----------------------------------------------------------+
    | Backend API                                                |
    | - FastAPI services                                         |
    | - PostgreSQL persistence                                   |
    | - file storage                                             |
    | - role-based access                                        |
    | - sync endpoints                                           |
    +-----------------------------------------------------------+

### Software principles

- offline-first by design
- encrypted local storage on device
- server-side authorization for all sensitive actions
- tamper-evident audit chain using previous hash linkage
- explicit separation between presumptive field result and confirmatory lab result in UI and API models
- modular assay configuration layer rather than fixed chemistry assumptions

---

## 4. Data flow diagram

    [Physical evidence received]
                ↓
    [Case registration]
                ↓
    [Sample ID assigned]
                ↓
    [Secure packing and sealing]
                ↓
    [Field officer / mobile app]
                ↓
    [Device connection via BLE]
                ↓
    [Run start + telemetry]
                ↓
    [Prepared aliquot + assay workflow]
                ↓
    [Detection strip readout]
                ↓
    [Computer vision validation]
                ├── if control fails → INVALID TEST → repeat using approved workflow
                └── if control passes → presumptive result capture
                            ↓
                    [hash image + record]
                            ↓
                    [append custody event]
                            ↓
                    [preserve original evidence]
                            ↓
                    [queue FSL handoff]
                            ↓
                    [authorized FSL receives sample]
                            ↓
                    [confirmatory lab result entered]
                            ↓
                    [digitally signed case record]
                            ↓
                    [case finalization]

### Data flow rule

The field application records a presumptive result as a screening signal only. The confirmatory lab process is represented as a separate result stream and is never merged into the field result record.

---

## 5. Database ER diagram

    users
      PK user_id
      role
      officer_id
      name
      password_hash
      status
      created_at

    cases
      PK case_id
      case_number
      title
      location
      created_by_user_id FK
      created_at

    samples
      PK sample_id
      case_id FK
      sample_code
      sample_type
      location
      officer_name
      date
      time
      notes
      gps_lat
      gps_lon
      device_id FK
      operator_id FK
      sealed_status
      preserved_status
      created_at

    devices
      PK device_id
      device_name
      serial_number
      hw_version
      status
      last_seen_at
      public_key_id

    test_runs
      PK test_run_id
      sample_id FK
      device_id FK
      assay_profile_id
      status
      started_at
      completed_at
      run_metadata

    field_results
      PK field_result_id
      test_run_id FK
      sample_id FK
      status
      target_indication
      control_valid
      quality_score
      image_ref
      raw_result_payload
      recorded_by_user_id FK
      recorded_at
      previous_record_hash
      current_record_hash

    evidence_images
      PK image_id
      sample_id FK
      test_run_id FK
      storage_uri
      image_hash
      image_metadata
      captured_by_user_id FK
      captured_at

    custody_events
      PK custody_event_id
      sample_id FK
      event_type
      who_user_id FK
      what_action
      when_ts
      where_location
      notes
      previous_hash
      current_hash
      is_immutable

    fsl_handoffs
      PK handoff_id
      sample_id FK
      destination_lab
      field_status
      physical_sample_status
      qr_code_value
      dispatched_by_user_id FK
      dispatched_at
      receiving_acknowledged_at

    lab_results
      PK lab_result_id
      sample_id FK
      confirmatory_method
      confirmatory_result
      analyst_user_id FK
      result_document_uri
      signed_at
      previous_hash
      current_hash
      status

    audit_logs
      PK audit_log_id
      sample_id FK
      entity_type
      entity_id
      action
      actor_user_id FK
      timestamp
      summary
      previous_hash
      current_hash

### Relationship summary

- case 1 -> many samples
- sample 1 -> many custody events
- sample 1 -> many test runs
- test run 1 -> many result records
- sample 1 -> zero or many lab result updates

---

## 6. API architecture

### API layer model

    Client Apps (Flutter / web app)
                │
                ▼
    API Gateway / authentication layer
                │
                ▼
    FastAPI application
                │
      ┌─────────┼─────────┐
      │         │         │
      ▼         ▼         ▼
  Auth       Case       Sample
  Routes     Routes     Routes
      │         │         │
      ▼         ▼         ▼
  Device     Test Run   Field Result
  Routes     Routes     Routes
      │         │         │
      ▼         ▼         ▼
  Evidence   FSL / Lab  Audit / Reporting
  Routes     Routes     Routes

### Core endpoints

- POST /auth/login
- POST /auth/demo-login
- POST /cases
- GET /cases/{case_id}
- POST /samples
- GET /samples/{sample_id}
- POST /samples/{sample_id}/custody-events
- POST /devices/connect
- POST /devices/{device_id}/telemetry
- POST /test-runs
- POST /test-runs/{id}/telemetry
- POST /field-results
- POST /evidence-images
- POST /fsl-handoffs
- POST /lab-results
- GET /audit/{sample_id}
- GET /case-summary/{case_id}

### API security requirements

- all endpoints require role-based authorization
- token-based access for field officers, supervisors, FSL analysts, and administrators
- signed payloads for device-to-server communication where applicable
- encrypted transport using HTTPS/TLS
- server-side validation of every operation and sample ownership
- immutable access patterns for custody and audit events

---

## 7. Mobile app screen map

    SpeciesTrace
      ├── Secure Login
      │     - Officer ID
      │     - Password
      │     - Demo login option
      │
      ├── Dashboard
      │     - Active cases
      │     - Today's samples
      │     - Pending FSL confirmation
      │     - Field results
      │     - Sync status
      │     - + New forensic sample
      │
      ├── Create Sample
      │     - Case / FIR number
      │     - Sample type
      │     - Location
      │     - Officer name
      │     - Date / time
      │     - Notes
      │     - QR / barcode generation
      │     - auto metadata capture
      │
      ├── Chain of Custody Timeline
      │     - registered
      │     - sealed + packaged
      │     - field test started
      │     - field result recorded
      │     - confirmatory sample dispatched
      │     - immutable event detail records
      │
      ├── Device Connection
      │     - NP FIELD UNIT 01
      │     - connected status
      │     - current temperature
      │     - amplification state
      │     - progress bar
      │
      ├── Result Capture
      │     - camera capture
      │     - strip detection
      │     - perspective correction
      │     - control region detection
      │     - control validation
      │     - detection zone reading
      │     - invalid test handling
      │
      ├── Field Result
      │     - PRESUMPTIVE FIELD RESULT
      │     - target indication
      │     - not detected panel statuses
      │     - legal warning text
      │     - test image
      │     - quality score
      │     - actions: save, memo, send for confirmation
      │
      ├── Digital Evidence Record
      │     - case ID
      │     - sample ID
      │     - barcode
      │     - officer
      │     - timestamp
      │     - location
      │     - device ID
      │     - test run ID
      │     - field result status
      │     - hashes and audit trail
      │
      └── FSL Handoff
            - confirmatory sample request
            - destination authorized FSL
            - QR / barcode handoff
            - physical sample status

---

## 8. FSL portal screen map

    FSL Portal
      ├── Login / Role Selection
      │     - Field Officer
      │     - Supervisor
      │     - FSL Analyst
      │     - FSL Administrator
      │
      ├── Case Dashboard
      │     - active cases
      │     - samples pending review
      │     - handoffs awaiting receipt
      │
      ├── Sample Intake
      │     - scan sample barcode
      │     - view chain of custody
      │     - verify receipt
      │     - record accession
      │
      ├── Confirmatory Workflow
      │     - method selection
      │     - confirmatory result entry
      │     - document upload
      │     - digital signature
      │     - case close / update
      │
      ├── Evidence Comparison View
      │     - field result: PRESUMPTIVE
      │     - lab result: CONFIRMATORY
      │     - never merged in same status banner
      │
      ├── Audit History
      │     - timeline events
      │     - hash validation
      │     - signed records
      │
      └── Case Finalization
            - final report status
            - evidence disposition
            - archive and closure

---

## 9. Security architecture

    [Field device]
          │
          ├── secure boot concept
          ├── signed firmware updates
          ├── unique device identity
          └── encrypted BLE session

    [Mobile app]
          │
          ├── biometric / PIN secure login
          ├── encrypted local SQLite storage
          ├── offline queue with secure sync
          ├── operator identity and device ID capture
          ├── image hashing before upload
          ├── evidence record hashing
          └── tamper-evident append-only event ledger

    [Backend]
          │
          ├── role-based access control
          ├── server-side authorization
          ├── TLS protected transport
          ├── secure object storage
          ├── audit log generation
          ├── conflict handling for offline edits
          └── integrity validation of chain-of-custody events

    [FSL portal]
          │
          ├── restricted analyst access
          ├── digital signature workflow
          ├── evidence receipt verification
          ├── controlled result finalization
          └── immutable closed-case history

### Security principles

- no result record is accepted without valid user role
- no chain-of-custody event can be silently edited after signing
- field imaging and result records are hashed before synchronization
- previous hash linkage creates append-only audit sequencing
- offline mode stores encrypted local data and queues sync when network is restored

---

## 10. Hackathon MVP vs future production roadmap

### Hackathon MVP

- single Android-first mobile app flow for case and sample creation
- mock or simulated thermal device telemetry via BLE
- camera-based strip capture with deterministic OpenCV validation flow
- field result entry with explicit presumptive status banner
- immutable-style chain-of-custody event timeline
- local encrypted storage and offline sync queue
- FSL portal mock dashboard for receipt and confirmatory result entry
- demo data generator with realistic case flow

### Future production roadmap

    Phase 1: field deployment prototype
      - rugged enclosure prototype
      - validated assay profiles by authorized lab
      - secure mobile app distribution and role control
      - improved BLE and sync reliability
      - digital signature for custody events

    Phase 2: field validation and certification readiness
      - manufacturer quality system
      - calibration and maintenance procedures
      - supply chain traceability for cartridges
      - eDiscovery and audit export tools

    Phase 3: modular assay expansion
      - additional species panels configured by authorized assay profiles
      - enhanced detection modules
      - FSL integration with LIS or lab systems

    Phase 4: enterprise forensic workflow
      - multi-agency case sharing controls
      - chain-of-custody interoperability standards
      - advanced analytics and reporting
      - cloud high-availability infrastructure

### Key production guardrails

- no unauthorized assay claims
- no final legal claims from the field result
- explicit approved workflow gating for every chemistry profile
- role separation between field and forensic confirmation responsibilities
- maintain evidence integrity and chain-of-custody continuity at all steps

---

## Human impact design summary

    ALLEGATION / SEIZURE
            ↓
    SPECIES DISPUTED
            ↓
    CURRENT SYSTEM:
    WAIT FOR LAB SIGNAL
            ↓
    UNCERTAINTY

    VERSUS

    SPECIESTRACE:
    EARLY PRESUMPTIVE SIGNAL
            ↓
    BETTER CASE TRIAGE
            ↓
    FASTER INVESTIGATIVE DIRECTION
            ↓
    CONFIRMATION STILL DONE BY FSL

This system is not meant to prove innocence, prevent arrest, or replace legal forensic determination. It provides earlier objective screening information that may support better investigative triage while final legal and forensic determination remains with the authorized laboratory and applicable procedures.

---

## Design constraints summary

- The prototype must clearly separate field and laboratory outcomes.
- No fabricated scientific performance claims.
- The assay workflow must be modular and research/validation dependent.
- The chain-of-custody system must be tamper-evident and append-only in concept.
- The mobile app must work offline-first and synchronize securely when network is restored.
- The project must feel like police forensic infrastructure, not consumer health technology.

This architecture is ready for review. Once approved, the next phase will be implementation module by module.
