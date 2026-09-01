# Learning Platform — Mobile App

Flutter app for the learner flow, built against the FastAPI backend in `../backend/`.
See `../PROCESS_FLOW.md` section 1 for the flow this implements.

## Getting started

```bash
flutter pub get

# Android emulator (10.0.2.2 is the emulator's alias for the host's localhost):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# iOS simulator / physical device on the same network:
flutter run --dart-define=API_BASE_URL=http://<your-host-ip>:8000/api/v1
```

The backend must be running (see `../backend/README.md`). `API_BASE_URL` defaults to
`http://10.0.2.2:8000/api/v1` (see `lib/config.dart`) so a plain `flutter run` on an Android
emulator works with no flags; override it for iOS simulators or physical devices, which can't
resolve `10.0.2.2`.

Debug builds allow plain-HTTP traffic (`android/app/src/debug/AndroidManifest.xml` sets
`usesCleartextTraffic="true"`) so the app can reach a local `http://` backend — Android blocks
cleartext by default since API 28. Release builds stay locked down; point them at an HTTPS
backend instead of loosening that for release.

**Running on a physical device** (not an emulator): `10.0.2.2` only resolves inside the Android
emulator's virtual network — a real phone needs this machine's actual LAN IP, and both must be on
the same Wi-Fi. `.vscode/launch.json` has a "mobile (LAN device...)" configuration pre-filled with
this machine's IP at the time of writing; if it stops connecting, the IP likely changed (DHCP) —
find the current one and update `toolArgs` there, or pass
`--dart-define=API_BASE_URL=http://<new-ip>:8000/api/v1` directly.

## Structure

```
lib/
  config.dart     API_BASE_URL (overridable via --dart-define) + media URL origin
  models/         plain Dart classes mirroring the backend's Pydantic schemas
  api/            one class per backend resource (courses, lessons, quizzes, progress),
                  plus api_client.dart (shared Dio + 401-refresh interceptor) and
                  api_error.dart (extracts a human message from a DioException)
  state/          AuthStore — the only global (ChangeNotifier) store: tokens + current user,
                  persisted via flutter_secure_storage
  router/         go_router routes + a redirect guard requiring an authenticated user
  screens/        one screen per flow step: auth, courses, lessons, quizzes, progress, profile
  widgets/        shared widgets: course_card, progress_bar, lesson_video_player, error_view
```

## Notes

- Mirrors the admin panel's conventions (`../admin/`) where they translate directly: a single
  auth store with a bare HTTP client for login/refresh/logout (so those calls can't recurse into
  the main client's 401 handling), and one API module per backend resource.
- **Lesson completion**: the backend only exposes progress in aggregate
  (`GET /progress/me`, `GET /progress/courses/{id}`) — it doesn't return per-lesson completion on
  `GET /courses/{id}/lessons`. `LessonsApi.listForCourseWithProgress` derives it client-side by
  checking each quiz's attempt history (`GET /quizzes/{id}/attempts`) for a passing attempt, since
  that's the only way a lesson ever gets marked complete server-side.
- **Video**: streamed with `video_player` + `chewie` straight from the backend's Range-enabled
  `/media` endpoint, so seeking works with no extra client code.
- **PDF/file lessons**: opened externally via `url_launcher` rather than an embedded viewer, to
  keep the app free of extra native dependencies — swap in an embedded viewer package later if
  in-app viewing is wanted.
- **Quiz taking**: `QuizScreen` requires every question answered before submitting; results
  (score, pass/fail, per-question correctness) come back from `POST /quizzes/{id}/submit` and are
  shown on `QuizResultScreen`. A failed attempt offers "Retake quiz"; the backend allows unlimited
  resubmission.

## Verified

- `flutter analyze` — clean (two informational deprecation notices only).
- `flutter build web` — compiles successfully (web isn't a target platform for this app; this was
  only used to smoke-test the Dart code without needing an Android/iOS emulator).
