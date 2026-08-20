# SpeciesTrace — Neural Patrol mobile app

Flutter field application for the Neural Patrol / SpeciesTrace forensic
screening prototype. It implements the full officer-facing workflow from the
architecture spec: secure login, case/sample registration with QR + GPS
capture, simulated field-device connection and telemetry, camera-based strip
capture with a deterministic presumptive-result analyzer, a
PRESUMPTIVE FIELD RESULT record, an append-only chain-of-custody timeline,
a digital evidence record, and FSL handoff.

The app is **offline-first**: every write (case, sample, custody event,
field result, FSL handoff) is tried against the FastAPI backend first and,
if the network is unreachable, is saved locally and queued for automatic
sync the next time the backend is reachable. A "Demo Login" also works with
zero backend running at all, so the app is demoable standalone.

This is a screening/demo prototype. Field results are always presented as
**presumptive only** — never a final forensic or legal conclusion.

## One-time project setup

This repo ships only the Dart application source (`lib/`) and
`pubspec.yaml` — the native `android/` and `ios/` platform folders are
generated locally with the Flutter tool (they're large, machine-specific,
and not meaningful to hand-author).

1. Install the Flutter SDK (3.3+) and either Android Studio (for Android) or
   Xcode (for iOS), then run `flutter doctor` until it's happy.
2. From this `mobile/` directory, scaffold the platform projects. This is
   safe to run against the existing source — it only adds the platform
   folders, it will not overwrite `lib/` or `pubspec.yaml`:
   ```
   flutter create .
   flutter pub get
   ```
3. Add the permissions the app needs (camera for strip capture, location for
   evidence GPS tagging) — `flutter create` doesn't add these by default:

   **`android/app/src/main/AndroidManifest.xml`** — inside the `<manifest>`
   tag, above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```

   **`ios/Runner/Info.plist`** — inside the top-level `<dict>`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Used to photograph the field detection strip for presumptive species screening.</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Used to attach an existing photo of the field detection strip.</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Used to record the GPS location of a collected sample for the chain of custody.</string>
   ```
4. Run the backend (from the repo root):
   ```
   cd backend
   python -m pip install -r requirements.txt
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
5. Run the app:
   ```
   flutter run
   ```

## Pointing the app at the backend

- **Android emulator**: works out of the box — the app defaults to
  `http://10.0.2.2:8000`, which the emulator maps to your machine's
  `localhost:8000`.
- **Physical device / iOS simulator on the same Wi-Fi**: on the login
  screen tap the small server address link at the bottom (or open the
  navigation drawer → *Backend connection* once logged in) and enter your
  machine's LAN IP, e.g. `http://192.168.1.23:8000`. Use *Test connection*
  to confirm reachability before saving.
- **No backend at all**: tap **DEMO LOGIN**. If the backend can't be
  reached, the app automatically continues in a fully local offline demo
  session — every screen still works, data is just queued for sync instead
  of hitting the server.

## Demo accounts

- Officer ID `DEMO-001`, password `demo1234` (seeded automatically by the
  backend), or just tap **DEMO LOGIN**.

## App structure

```
lib/
  data/repository.dart       online-first data layer with offline queue + sync
  models/                    typed models mirroring the backend schemas
  services/                  API client, local cache, GPS, strip analyzer
  state/app_session.dart     auth/session state
  screens/                   one file per screen in the workflow
  widgets/                   shared UI (banners, status pills, drawer, etc.)
```

## Note on the strip analyzer

`services/strip_analyzer.dart` is a deterministic, on-device stand-in for the
OpenCV/multiplex lateral-flow reader described in the architecture doc — it
hashes the captured photo so the same image always reproduces the same
presumptive result during a demo. A real deployment replaces this with the
validated chemistry + trained strip-reader model; nothing else in the app
needs to change since it only depends on the `StripAnalysisResult` shape.
