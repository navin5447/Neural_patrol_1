# NEURAL PATROL — SPECIESTRACE DEPLOYMENT GUIDE

This document provides complete instructions, architecture details, and production rules for deploying the **Neural Patrol (SpeciesTrace)** system across **Vercel** (React Portal), **Render** (FastAPI Backend), Docker containers, Cloud VPS, and mobile applications.

---

## 1. System Architecture Overview

The SpeciesTrace platform comprises three core deployable units:

```
                      +-----------------------------+
                      |   Field Mobile App (Flutter)|
                      +--------------+--------------+
                                     | (HTTPS API)
                                     v
+------------------------+    +-----------------------+    +-----------------------+
|  FSL & Admin Dashboard |<-->|  FastAPI Backend API  |<-->| Database (SQLite /    |
|  (Hosted on Vercel)    |    |  (Hosted on Render)   |    |  PostgreSQL)          |
+------------------------+    +-----------------------+    +-----------------------+
```

1. **Backend API (`/backend`)**: FastAPI REST API handling evidence intake, presumptive species screening, user authentication, and FSL handoff workflows. Hosted on **Render**.
2. **Web Portal (`/portal`)**: React + Vite admin and lab review dashboard. Hosted on **Vercel**.
3. **Mobile App (`/mobile`)**: Flutter field application for mobile screening, camera image processing, offline queueing, and backend synchronization.

---

## 2. Cloud PaaS Deployment: Vercel & Render (Recommended Cloud Setup)

Deploying the React Web Portal on **Vercel** and the FastAPI Backend on **Render** provides automatic HTTPS, global CDN distribution, and continuous deployment straight from GitHub.

---

### Part A: Deploy Backend to Render (`/backend`)

#### Option 1: Automatic Deployment using Render Blueprint (Recommended)
1. Push your repository to **GitHub**.
2. Log in to [Render Dashboard](https://dashboard.render.com/).
3. Click **New +** -> **Blueprints**.
4. Connect your GitHub repository (`Askar7863/Neural_patrol`).
5. Render will automatically detect [`render.yaml`](file:///c:/Users/Navinkumar/Downloads/Neuralpatrol/Neural_patrol/render.yaml) and configure:
   - **Service Name:** `speciestrace-backend`
   - **Root Directory:** `backend`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path:** `/health`
6. Click **Apply**. Once deployed, Render will provide your public backend URL (e.g. `https://speciestrace-backend.onrender.com`).

#### Option 2: Manual Web Service Creation on Render
If setting up manually via the Render dashboard:
1. Click **New +** -> **Web Service**.
2. Select repository and set:
   - **Name:** `speciestrace-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
3. Under **Environment Variables**, add:
   - `ENVIRONMENT`: `production`
   - `SECRET_KEY`: `generate_a_secure_64_character_random_string`
   - `ALLOWED_ORIGINS`: `*` (or your specific Vercel URL `https://your-app.vercel.app`)

---

### Part B: Deploy Web Portal to Vercel (`/portal`)

#### Deploy via Vercel Web Dashboard:
1. Log in to [Vercel Dashboard](https://vercel.com/dashboard).
2. Click **Add New...** -> **Project**.
3. Import your GitHub repository (`Askar7863/Neural_patrol`).
4. Configure project settings:
   - **Framework Preset:** Vite
   - **Root Directory:** Select `portal` (click Edit -> select `portal`).
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
5. Click **Deploy**. Vercel will process the build using [`portal/vercel.json`](file:///c:/Users/Navinkumar/Downloads/Neuralpatrol/Neural_patrol/portal/vercel.json) and issue your live domain (e.g., `https://speciestrace-portal.vercel.app`).

#### Deploy via Vercel CLI (Alternative):
```bash
npm install -g vercel
cd portal
vercel
```

---

## 3. Quick-Start Docker Deployment (Self-Hosted / VPS)

### Prerequisites
- [Docker Engine](https://docs.docker.com/engine/install/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)

### Step-by-Step Deployment

1. **Clone the repository onto your host server:**
   ```bash
   git clone https://github.com/Askar7863/Neural_patrol.git
   cd Neural_patrol
   ```

2. **Set up Environment Variables:**
   Copy `.env.example` to `.env` and configure your settings:
   ```bash
   cp .env.example .env
   ```

3. **Build and Launch Services:**
   ```bash
   docker compose up -d --build
   ```

4. **Verify Deployment:**
   - **Backend Status:** `curl http://localhost:8000/health`
   - **Web Portal:** Access `http://<your-server-ip>:3000` in your browser.

---

## 4. Mobile App Deployment (Flutter)

### Step 1: Configure Backend Endpoint
Update the API base URL in `mobile/lib/config.dart` (or environment settings) to point to your live Render backend URL:
```dart
const String apiBaseUrl = "https://speciestrace-backend.onrender.com";
```

### Step 2: Build Android Release Package
```bash
cd mobile

# Build standalone APK file for direct installation
flutter build apk --release

# Output path: build/app/outputs/flutter-apk/app-release.apk

# Build Google Play Store Bundle (.aab)
flutter build appbundle --release
# Output path: build/app/outputs/bundle/release/app-release.aab
```

### Step 3: Build iOS Release Package (Mac Required)
```bash
cd mobile
flutter build ipa --release
```

---

## 5. Mandatory Production Rules & Security Policies

When deploying SpeciesTrace into production or forensic trial environments, enforce the following mandatory rules:

### Rule 1: Secret & Key Isolation
- Never commit `.env` files or plain text credentials to Git repositories.
- Always replace default `SECRET_KEY` values with high-entropy random strings (e.g. `openssl rand -hex 32`).

### Rule 2: Digital Evidence Integrity & Immutability
- SpeciesTrace distinguishes between **Presumptive Field Screening** and **Final FSL Laboratory Results**.
- Database entries in `AuditLog` and `FieldResult` tables must be append-only. Never run `UPDATE` or `DELETE` queries directly against audit log tables.

### Rule 3: CORS Security Policy for Vercel & Render
- Ensure `ALLOWED_ORIGINS` in Render backend settings is set to your exact Vercel frontend domain (e.g., `https://speciestrace-portal.vercel.app`) to block unauthorized cross-site requests while permitting your portal dashboard.

### Rule 4: HTTPS Enforcement & API Security
- Do not expose HTTP endpoints publicly in production environments. Enforce TLS 1.2+ HTTPS for all mobile application requests to protect sensitive location and case data.
