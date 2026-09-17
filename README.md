# LiftLog - Modern Workout Tracking System

A production-grade, secure, multi-tenant workout tracking application built with a modern three-tier architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                     │
│                  (iOS, Android, macOS, Web)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS REST API
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Node.js + TypeScript Backend                │
│             (Express + Mongoose + JWT Auth)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ Reusable Singleton Connection
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     MongoDB Atlas Cloud                     │
│               (Multi-Tenant Scoped Documents)               │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Architectural Principles

1. **Zero Database Credentials on the Mobile Client**:
   - The Flutter application never connects directly to MongoDB Atlas.
   - `mongo_dart` is completely removed.
   - No `MONGODB_URI`, database usernames, passwords, or connection strings are present anywhere in Flutter code, assets, `Info.plist`, or Android manifests.
2. **Dedicated Backend API**:
   - Built with **Node.js, TypeScript, Express, and Mongoose**.
   - Encapsulates database connection management, connection lifecycle events, and query execution.
   - Strictly waits for the MongoDB Atlas connection before opening the HTTP port to accept requests.
   - Guards against unready states and handles reconnects safely.
3. **Strict Multi-Tenant Security & Ownership Enforcement**:
   - Every user-owned document (`WorkoutPlan`, `Exercise`, `WorkoutSession`, `PersonalRecord`, `AppSettings`) contains an indexed `userId`.
   - Client-supplied `userId` inputs are never trusted. The backend derives and validates `userId` strictly from cryptographically signed JWT bearer tokens via `requireAuth` middleware.
   - Every database query (`find`, `findOne`, `findOneAndUpdate`, `deleteOne`, etc.) enforces `{ id, userId: req.userId }`. User A can never read, modify, or delete User B's training records.
4. **Resilient Flutter API Client**:
   - Robust `ApiClient` with configurable base URLs (`--dart-define=API_BASE_URL=...`).
   - Secure token storage using `SharedPreferences`.
   - Automatic 401 token refresh and session handling.
   - Friendly network error states, loading skeletons, and empty states.
   - Workouts screen fetches real plans; shows `"No workout plans yet"` when empty without inserting fake mock data.

---

## Directory Structure

```
liftlog/
├── backend/                        # Node.js + TypeScript REST API
│   ├── src/
│   │   ├── db/
│   │   │   └── connection.ts       # Singleton Mongoose connection manager
│   │   ├── middleware/
│   │   │   └── auth.ts             # JWT authentication & DB ready guards
│   │   ├── models/
│   │   │   ├── User.ts             # User schema with bcrypt hash & refresh token
│   │   │   ├── WorkoutPlan.ts      # Workout plans with multi-tenant userId
│   │   │   ├── Exercise.ts         # Predefined library + custom exercises
│   │   │   ├── WorkoutSession.ts   # Session logs & set logs
│   │   │   ├── PersonalRecord.ts   # Auto-evaluated PR benchmarks
│   │   │   └── AppSettings.ts      # User preferences and units
│   │   ├── routes/
│   │   │   ├── health.ts           # GET /api/health
│   │   │   ├── auth.ts             # Register, Login, Google OAuth, Refresh, Logout
│   │   │   ├── workoutPlans.ts     # CRUD & duplicate workout plans
│   │   │   ├── exercises.ts        # CRUD exercises + standard library seeding
│   │   │   ├── workoutSessions.ts  # Active & completed session tracking
│   │   │   ├── personalRecords.ts  # PR records and benchmarks
│   │   │   ├── analytics.ts        # History, statistics, and reports
│   │   │   └── settings.ts         # Settings, profile, export/import, delete
│   │   ├── app.ts                  # Express app assembly & CORS
│   │   └── server.ts               # Startup entrypoint waiting for MongoDB Atlas
│   ├── test/
│   │   └── backend.test.ts         # Automated backend & isolation test suite
│   ├── .env.example                # Template for environment variables
│   ├── package.json
│   └── tsconfig.json
├── lib/                            # Flutter Mobile Client
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart     # HTTP client with retry, refresh & tokens
│   │   │   └── api_config.dart     # Dynamic base URL resolution
│   │   ├── constants/
│   │   ├── theme/
│   │   └── widgets/
│   ├── data/
│   │   ├── models/                 # Pure Dart domain models
│   │   ├── repositories/           # Repositories calling ApiClient
│   │   └── services/               # AuthService calling REST endpoints
│   ├── features/                   # Glassmorphism UI screens & widgets
│   ├── providers/                  # Riverpod state notifiers
│   └── main.dart                   # Application initialization
└── test/
    ├── api_client_and_repositories_test.dart  # Flutter unit & repository tests
    └── widget_test.dart                       # Flutter widget tests
```

---

## 1. MongoDB Atlas Configuration

1. Log in to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
2. Create or select your database cluster (e.g. `liftlog`).
3. Under **Security** → **Database Access**:
   - Create a database user (e.g., `liftlog_api_user`).
   - Assign **Read and write to any database** privileges.
   - Use password authentication.
4. Under **Security** → **Network Access**:
   - Add your server's IP address to the **IP Access List**.
   - For local development with dynamic IPs, add `0.0.0.0/0` (Allow Access from Anywhere) or add your current external IP.
5. In **Databases** → **Connect**:
   - Choose **Connect your application** (Driver: Node.js).
   - Copy the SRV connection string:
     ```text
     mongodb+srv://<username>:<password>@<cluster-host>/<database>?retryWrites=true&w=majority
     ```
   - Replace `<username>`, `<password>`, and `<database>` with your actual credentials.

---

## 2. Backend Setup & Configuration

### Environment Variables (`backend/.env`)

Copy `backend/.env.example` to `backend/.env` (do NOT commit `.env` to version control):

```bash
cd backend
cp .env.example .env
```

Fill in the environment variables:

```env
# Server Port
PORT=5000

# MongoDB Atlas Connection URI (kept securely on backend only)
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/liftlog?retryWrites=true&w=majority

# Cryptographic JWT Secrets
JWT_SECRET=generate_a_strong_random_secret_string_here_32_chars_min
JWT_REFRESH_SECRET=generate_another_strong_random_secret_string_here

# Google OAuth Web Client ID
GOOGLE_CLIENT_ID=920575978481-6ss9gbv10qu2dlo4888fcu0nu75iktv5.apps.googleusercontent.com
```

### Install Dependencies & Build

```bash
cd backend
npm install
npm run build
```

### Run the Backend

- **Development Mode** (with automatic hot-reloading):
  ```bash
  npm run dev
  ```
- **Production Mode**:
  ```bash
  npm run build
  npm start
  ```

### Run Backend Verification Tests

The backend test suite verifies live connection readiness, health status, registration, workout plan creation, and multi-tenant security isolation:

```bash
npm test
```

---

## 3. Google OAuth Configuration

### Google OAuth Configuration

The Google OAuth client IDs configured for this application are:

- **Web Client ID (serverClientId & Backend Token Audience):**
  ```text
  920575978481-6ss9gbv10qu2dlo4888fcu0nu75iktv5.apps.googleusercontent.com
  ```
- **Android OAuth Client ID:**
  ```text
  920575978481-snf8lhc8o7sel63he5c4futmlfhe7e1u.apps.googleusercontent.com
  ```
  - Package Name: `com.example.liftlog`
  - Debug SHA-1: `32:BB:51:BF:A6:05:FF:CB:FA:40:D9:A5:01:82:1E:6E:45:4D:A4:95`

- **Backend (`/api/auth/google`)**:
  - Uses `google-auth-library` (`OAuth2Client`).
  - Verifies the integrity and audience of the incoming Google ID token (`920575978481-6ss9gbv10qu2dlo4888fcu0nu75iktv5.apps.googleusercontent.com`).
  - Automatically provisions or matches the user in MongoDB Atlas and signs a secure JWT session.
- **Flutter Client**:
  - Uses `GoogleSignIn(serverClientId: ApiConfig.googleClientId)` where `ApiConfig.googleClientId` points to the Web Client ID.
  - Google Play Services automatically resolves the Android client using the app's package name and debug keystore SHA-1.
  - iOS configuration is maintained separately and remains untouched.

---

## 4. API Health & Endpoints Reference

### Health Check
- `GET /api/health`
  - Returns server status, uptime, and database connection state:
    ```json
    {
      "status": "ok",
      "timestamp": "2026-09-15T10:30:00.000Z",
      "uptimeSeconds": 120,
      "database": {
        "connected": true,
        "state": "connected",
        "provider": "MongoDB Atlas"
      }
    }
    ```

### Authentication Endpoints
- `POST /api/auth/register`: Create user account with `{ name, email, password }`.
- `POST /api/auth/login`: Authenticate with `{ email, password }`.
- `POST /api/auth/google`: Sign in with Google ID token `{ idToken }`.
- `GET /api/auth/me`: Get current authenticated user profile.
- `POST /api/auth/refresh`: Refresh JWT using `{ refreshToken }`.
- `POST /api/auth/logout`: Revoke active session refresh token.

### Training & Workout Endpoints
- `GET /api/workout-plans`: List user workout plans (supports `?query=...`).
- `POST /api/workout-plans`: Create/update workout plan.
- `GET /api/workout-plans/:id`: Retrieve single plan by ID.
- `PUT /api/workout-plans/:id`: Update plan by ID.
- `DELETE /api/workout-plans/:id`: Delete plan by ID.
- `POST /api/workout-plans/:id/duplicate`: Duplicate workout plan.
- `GET /api/exercises`: List library and custom exercises.
- `POST /api/exercises`: Create custom exercise.
- `GET /api/workout-sessions/active`: Fetch active/in-progress session.
- `GET /api/workout-sessions`: Fetch session history with filters.
- `POST /api/workout-sessions`: Save completed or active session with set logs.
- `DELETE /api/workout-sessions/:id`: Delete session.
- `GET /api/personal-records`: Fetch personal records benchmarks.
- `POST /api/personal-records`: Record new personal record.
- `GET /api/history`: Fetch completed workout history.
- `GET /api/statistics`: Fetch aggregated volume, reps, and workout counts.
- `GET /api/reports`: Fetch muscle group breakdown and consistency summaries.
- `GET /api/settings`: Retrieve user preferences and units.
- `PUT /api/settings`: Update user preferences.
- `PUT /api/users/profile`: Update user profile name and fitness goal.

---

## 5. Flutter Client Setup & Environment Configuration

### Base URL Resolution (`ApiConfig`)

The Flutter app connects to the REST API via `ApiClient`. Configure the backend URL at build or run time using `--dart-define=API_BASE_URL=...`.

1. **iOS Simulator / macOS Desktop**:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
   ```
2. **Android Emulator**:
   Android emulators access the host machine's `localhost` via `10.0.2.2`. This is configured as the default fallback for Android:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
   ```
3. **Physical iOS / Android Devices (over local Wi-Fi)**:
   Use your computer's local network IP address (e.g. `192.168.1.50`):
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5000/api
   ```
4. **Production Deployment**:
   ```bash
   flutter run --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api
   ```

### Run Flutter Analysis & Tests

```bash
flutter analyze
flutter test
```

Both should pass with 0 errors and 0 warnings.
