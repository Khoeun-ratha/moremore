# Learning Platform — Admin Panel

Vue 3 + TypeScript admin panel for the learning platform, built with Vite and Element Plus.
Talks to the FastAPI backend in `../backend/`. See `../PROCESS_FLOW.md` for the overall system
and admin flow.

## Getting started

```bash
cp .env.example .env   # set VITE_API_BASE_URL if the backend isn't on localhost:8000
npm install
npm run dev
```

The backend must be running (see `../backend/README.md`) and its `CORS_ORIGINS` must include this
app's dev origin (`http://localhost:5173` by default — already set in `backend/.env.example`).

## Build

```bash
npm run build   # type-checks with vue-tsc, then builds to dist/
```

## Structure

```
src/
  api/          one module per backend resource (courses, lessons, quizzes, users, files),
                plus http.ts: the shared axios instance with the 401-refresh interceptor
  stores/       auth.ts — the only global (Pinia) store: tokens + current user
  router/       routes + a guard requiring an authenticated admin user
  types/        TS interfaces mirroring the backend's Pydantic schemas
  composables/  useQuizForm.ts — dynamic question/choice quiz builder state
  components/   AppLayout.vue (sidebar/header/logout), FileUploader.vue (upload → URL)
  views/        one view per screen: auth, dashboard, courses, lessons, quizzes, users
```

## Notes

- Only admins can use this panel — the login screen rejects non-admin accounts client-side, and
  every admin-only backend route enforces it server-side regardless.
- The quiz builder's "edit" mode calls the admin-only `GET /quizzes/{id}/full` endpoint to see
  which choice is currently correct (the learner-facing quiz endpoints never expose that).
- File uploads (video/PDF/image) go straight to the backend's local disk storage via
  `POST /files/upload`; the returned URL is what gets saved on the lesson.
