# Learning Platform — Backend API

FastAPI backend for a learning platform: books/courses containing lessons (video + PDF + text),
per-lesson quizzes with scoring, and per-user progress tracking. Stage 1 of a larger system that
will also include a React/Vue admin panel and a Flutter mobile app (built against this API).

## Stack

- FastAPI + Pydantic v2
- SQLAlchemy 2.0 (sync) + PyMySQL, targeting MySQL 8
- Alembic migrations
- JWT auth (access + DB-revocable refresh tokens), bcrypt password hashing
- Local disk file storage for videos/PDFs/images, served via `StaticFiles` (supports HTTP Range
  requests, so video seeking works without extra code)
- `slowapi` rate limiting on auth endpoints

## Getting started (Docker)

```bash
cp .env.example .env   # edit SECRET_KEY and other values
docker compose up --build
```

This starts MySQL, runs `alembic upgrade head`, and serves the API at http://localhost:8000.
Swagger UI: http://localhost:8000/docs. Adminer (DB browser): http://localhost:8080.

## Getting started (local, no Docker)

```bash
python -m venv .venv
source .venv/bin/activate   # .venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env        # point DATABASE_URL at your MySQL instance
alembic upgrade head
uvicorn app.main:app --reload
```

## Running tests

The test suite runs against `TEST_DATABASE_URL` (see `tests/conftest.py`). It defaults to a local
SQLite file so it runs anywhere without extra setup; point it at a real MySQL schema in CI for full
dialect parity before deploying.

```bash
pytest
```

## Project layout

```
app/
  core/       config, JWT + password hashing, auth dependencies, rate limiter, error handling
  db/         SQLAlchemy base + session/engine
  models/     ORM models
  schemas/    Pydantic request/response models
  api/v1/     routers per resource, aggregated in router.py
  services/   business logic (auth, quiz grading, progress, file storage, recommendations)
  main.py     app factory
alembic/      migrations
tests/        pytest suite
media/        uploaded files (gitignored)
```

## Data model

Course (book/course) → Lesson (video URL + PDF URL + text content) → Quiz (1:1) → Question → Choice.
QuizAttempt + QuizAttemptAnswer record scored submissions. LessonProgress tracks per-user completion;
course/overall progress is derived from it. See `../` plan doc or `app/models/` for full field lists.

## Auth flow

1. `POST /api/v1/auth/register` — creates a `user`-role account
2. `POST /api/v1/auth/login` — OAuth2 password form → `{access_token, refresh_token}`
3. Send `Authorization: Bearer <access_token>` on subsequent requests
4. `POST /api/v1/auth/refresh` when the access token expires (rotates the refresh token)
5. `POST /api/v1/auth/logout` revokes a refresh token

Admin-only endpoints (course/lesson/quiz CRUD, file upload, user management) require a user with
`role=admin`. Promote a user by editing their role directly in the DB, or via
`PATCH /api/v1/users/{id}` as an existing admin. There is no self-serve admin signup by design.

## File uploads

`POST /api/v1/files/upload?kind=video|pdf|image` (multipart form, field name `file`, admin only).
Validates extension per `kind`, enforces `MAX_UPLOAD_SIZE_MB`, stores under `media/{kind}s/<uuid>.ext`,
and returns a `url` you attach to a lesson's `video_url` or `file_url` field. Swappable for S3/MinIO
later — only `app/services/file_service.py` needs to change.

## Quizzes

Creating a quiz (`POST /api/v1/lessons/{lesson_id}/quiz`) takes nested questions + choices in one
payload; each question must have exactly one correct choice. Submitting
(`POST /api/v1/quizzes/{id}/submit`) grades against `is_correct`, stores a `QuizAttempt` +
per-question `QuizAttemptAnswer`, and marks the lesson complete automatically if the score meets
`passing_score`.

## Non-goals for this stage

- React/Vue admin panel and Flutter app (separate, later builds against this API)
- Real AI recommendations/adaptive quizzes — `app/services/recommendation_service.py` is a stubbed
  extension point (naive category-popularity heuristic) ready to be swapped for a model later
- S3/cloud storage — local disk now, behind an interface that can be swapped later
- Email verification / password reset flows
