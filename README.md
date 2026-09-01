# Learning Platform

A learning platform with three parts: a FastAPI backend, a Vue admin panel, and a Flutter mobile
app. See [`PROCESS_FLOW.md`](PROCESS_FLOW.md) for how the system works end to end.

```
backend/   FastAPI service — the API everything else talks to
admin/     Vue 3 admin panel (web) — manage courses, lessons, quizzes, users
mobile/    Flutter app — the learner-facing mobile experience
```

## Run everything (local, no Docker)

Each part runs in its own terminal. Start the backend first — the admin panel and mobile app both
need it running.

### 1. Backend (service)

Windows (Git Bash / this repo's default shell):

```bash
cd backend
python -m venv .venv
source .venv/Scripts/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

macOS / Linux:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

Serves the API at http://localhost:8000 (Swagger UI at `/docs`). Uses the existing `backend/.env`.

Or with Docker (also starts MySQL and Adminer):

```bash
cd backend
docker compose up --build
```

Full details: [`backend/README.md`](backend/README.md).

### 2. Admin panel (web)

```bash
cd admin
npm install
npm run dev
```

Opens at http://localhost:5173. Requires the backend running and an account with `role=admin`. Uses
the existing `admin/.env`.

Full details: [`admin/README.md`](admin/README.md).

### 3. Mobile app

Android emulator:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

iOS simulator / physical device on the same network:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<your-host-ip>:8000/api/v1
```

Requires the backend running. A plain `flutter run` on an Android emulator also works with no
flags, since `API_BASE_URL` already defaults to the emulator alias.

Full details: [`mobile/README.md`](mobile/README.md).

## Notes

- There's no self-serve admin signup — promote a user to `role=admin` directly in the database, or
  via `PATCH /api/v1/users/{id}` as an existing admin.
- The mobile app and admin panel are independent frontends against the same backend; either can run
  without the other, as long as the backend is up.
