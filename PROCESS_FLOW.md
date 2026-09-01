# Learning Platform — Process Flow Notes

Reference notes for how the system works end to end. Backend (Stage 1), admin panel (Stage 2),
and Flutter app (Stage 3) are all built against this API; see each stage's README for specifics.

## 1. End-user (learner) flow — mobile app

```
Open app
  └─ Has valid session? ──No──▶ Register or Login ──▶ Forgot password?
        │                         │  POST /api/v1/auth/register        │  POST /api/v1/auth/forgot-password {email}
        │                         │  POST /api/v1/auth/login            │    → emails a reset code (logged instead if
        │                         │    → {access_token, refresh_token}  │       SMTP isn't configured — see §3)
        │                         ▼                                     ▼
        │                                                        POST /api/v1/auth/reset-password {token, new_password}
        │                                                          → sets new password, revokes all existing sessions
        └─ Yes ──────────────▶ Home dashboard
                                   │  GET /api/v1/progress/me        (Continue Learning + Enrolled Courses)
                                   │  GET /api/v1/courses/recommended (category-affinity heuristic, excludes
                                   │                                    completed courses — see recommendation_service)
                                   ▼
                              Browse / search courses (Courses tab)
                                   │  GET /api/v1/courses?q=&category=&page=   (each item includes average_rating)
                                   ▼
                              Select a course
                                   │  GET /api/v1/courses/{id}                (rating summary + lesson_count)
                                   │  GET /api/v1/courses/{id}/lessons        (each lesson includes `completed`)
                                   │  GET /api/v1/courses/{id}/reviews        (Reviews tab)
                                   ▼
                              View lesson list — sequential unlock
                                   │  lesson N+1 is locked (🔒, tap blocked) until lesson N is completed
                                   ▼
                              Open a lesson
                                   │  GET /api/v1/lessons/{id}
                                   ├─ Watch video (video_url, streamed via /media, Range-enabled)
                                   ├─ Read/download file (file_url, PDF)
                                   ├─ Read text content
                                   └─ No quiz? → "Mark as Complete" button
                                        │  POST /api/v1/lessons/{id}/complete  (rejected 409 if the lesson has a quiz)
                                   │
                                   ▼
                              Take the lesson's quiz
                                   │  GET /api/v1/lessons/{id}/quiz   (choices, no answers exposed)
                                   ▼
                              Submit answers
                                   │  POST /api/v1/quizzes/{id}/submit
                                   │    → grades against stored correct choice
                                   │    → stores QuizAttempt + QuizAttemptAnswer
                                   │    → marks lesson complete if score ≥ passing_score
                                   ▼
                              View score / pass-fail result
                                   │  Failed? → "Retake Quiz" resets answers/progress and returns to question 1
                                   ▼
                              Continue learning → next lesson, or back to course list
                                   │
                                   ▼
                              Review a past result anytime from the lesson screen ("Your Attempts")
                                   │  GET /api/v1/quizzes/{quiz_id}/attempts        (list, most recent first)
                                   │  GET /api/v1/quizzes/attempts/{attempt_id}     (full question-by-question detail)
                                   ▼
                              Track progress
                                     GET /api/v1/progress/me            (all courses, overall %)
                                     GET /api/v1/progress/courses/{id}  (one course, %)
                                   ▼
                              Rate the course anytime from its Reviews tab
                                     PUT /api/v1/courses/{id}/reviews/me {rating: 1-5, comment}
                                       → creates or replaces *this user's own* review (one per user per course);
                                         average_rating/review_count on the course update immediately
                                   ▼
                              Complete every lesson → certificate auto-issued
                                     GET /api/v1/certificates/me   ("My Certificates", Profile tab)
                                       → issued the moment a user's last incomplete lesson in a course is marked
                                         done (via quiz pass or manual complete); one per user per course, never reissued
                                   ▼
                              Manage account (Profile tab)
                                     PATCH /api/v1/auth/me             {full_name}  — edit profile
                                     POST /api/v1/auth/change-password {current_password, new_password}
```

Session refresh happens transparently whenever the access token expires:
`POST /api/v1/auth/refresh` with the stored refresh token → new access+refresh pair (old refresh
token is revoked/rotated). `POST /api/v1/auth/logout` revokes the current refresh token.

**Lesson locking** is enforced client-side only (mirrors how the mobile app already derives other
per-user state) — lesson N+1's tile is shown locked and its tap is intercepted with a snackbar
until lesson N's `completed` flag is true. It is not enforced by the API.

## 2. Admin flow — web admin panel

```
Admin logs in (same /auth/login, account must have role=admin)
  │
  ├─ Manage courses
  │     POST/PATCH/DELETE /api/v1/courses          create/edit/remove a book or course
  │
  ├─ Manage lessons (per course)
  │     POST/PATCH/DELETE /api/v1/courses/{id}/lessons, /api/v1/lessons/{id}
  │
  ├─ Upload media for a lesson
  │     POST /api/v1/files/upload?kind=video|pdf|image
  │       → returns a URL → admin pastes it into the lesson's video_url / file_url field
  │
  ├─ Create/edit a quiz for a lesson
  │     POST/PATCH/DELETE /api/v1/lessons/{id}/quiz, /api/v1/quizzes/{id}
  │       (nested questions + choices in one payload; exactly one correct choice per question)
  │
  └─ View users & their progress
        GET /api/v1/users
        GET /api/v1/users/{id}/progress
```

There is no self-serve admin signup — an existing admin promotes a user via
`PATCH /api/v1/users/{id}` (`role: "admin"`), or it's set directly in the DB for the first admin.

## 3. Auth token lifecycle

```
register → login ──▶ access_token (short-lived, ~45 min)
                 └─▶ refresh_token (long-lived, ~14 days, hashed + stored in DB)

access_token expires ──▶ POST /auth/refresh {refresh_token}
                              │
                              ├─ valid & not revoked/expired → issues NEW access+refresh pair,
                              │                                 revokes the old refresh_token
                              └─ invalid/revoked/expired     → 401, user must log in again

logout ──▶ POST /auth/logout {refresh_token} → marks it revoked (can't be used again)

forgot-password ──▶ POST /auth/forgot-password {email}
                        → issues a short-lived (30 min), single-use reset code, hashed + stored in DB
                        → emails it (or logs it server-side if SMTP isn't configured); always 204,
                          regardless of whether the email is registered — avoids leaking who has an account

reset-password ──▶ POST /auth/reset-password {token, new_password}
                        → sets the new password, marks the code used, revokes ALL of that user's
                          existing refresh tokens (a reset means every prior session is untrusted)

change-password ──▶ POST /auth/change-password {current_password, new_password}  (requires login)
```

## 4. Quiz scoring logic

For each question in the quiz:
1. Look up the choice the user selected (if any) for that question.
2. Compare against the one `Choice` flagged `is_correct=True`.
3. Tally `score` = number of correct answers, `total` = number of questions.
4. `percentage = score / total * 100`; `passed = percentage >= quiz.passing_score`.
5. Persist a `QuizAttempt` (summary) + one `QuizAttemptAnswer` per question (for history/review).
6. If `passed`, mark the lesson's `LessonProgress.completed = True` for that user.

Every attempt stays reviewable afterwards, not just immediately after submitting:
`GET /quizzes/{quiz_id}/attempts` lists a user's own attempts (score, pass/fail, timestamp);
`GET /quizzes/attempts/{attempt_id}` returns one attempt's full question-by-question detail
(404s if the attempt belongs to a different user).

For lessons with no quiz, completion has no auto-graded signal, so the learner marks it done
directly: `POST /lessons/{lesson_id}/complete` sets `LessonProgress.completed = True` for that
user (409s if the lesson has a quiz — that lesson can only be completed by passing it).

Course-level and overall progress are *derived*, not stored directly: percentage of a course's
lessons that have a completed `LessonProgress` row for the current user.

Whenever `mark_lesson_complete` finishes marking a lesson, it checks whether every lesson in that
course is now complete for that user; if so and no `Certificate` exists yet, one is issued
(`certificate_number` is a random `CERT-XXXXXXXXXXXX` token, not sequential/guessable). This runs
identically whether completion came from passing a quiz or from the manual `/complete` endpoint.

`GET /courses/recommended` calls `recommendation_service.get_recommendations` — a heuristic that
was implemented early on but never wired to a route until now: courses in categories the current
user has engaged with (via any `LessonProgress`), ranked by recency, excluding courses they've
already completed. Swap the body of `get_recommendations` for a model-backed ranking later without
touching the endpoint or the mobile client.

## 5. Data ownership / cascade behavior

```
Course ──1:N──▶ Lesson ──1:1──▶ Quiz ──1:N──▶ Question ──1:N──▶ Choice
  │               │                │
  │               │                └──1:N──▶ QuizAttempt ──1:N──▶ QuizAttemptAnswer
  │               └──1:N──▶ LessonProgress (per user)
  ├──1:N──▶ Certificate (per user, unique on user+course)
  └──1:N──▶ CourseReview (per user, unique on user+course — upserted, never duplicated)
```

Deleting a Course cascades to its Lessons, Certificates, and CourseReviews; deleting a Lesson
cascades to its Quiz (and transitively Questions/Choices); deleting a Quiz cascades to its
Questions/Choices and QuizAttempts. User deletion cascades to their RefreshTokens,
PasswordResetTokens, QuizAttempts, LessonProgress, Certificates, and CourseReviews.

## 6. What's built vs what's next

- ✅ **Stage 1 — Backend API** (`backend/`): all of the above is implemented and covered by
  53 passing tests plus a live end-to-end smoke test.
- ✅ **Stage 2 — Admin panel** (`admin/`, Vue 3 + TypeScript): a web UI over the admin flow in
  section 2.
- ✅ **Stage 3 — Flutter app** (`mobile/`): a mobile UI over the learner flow in section 1 — auth
  (incl. password reset), a Home dashboard, course browse/search with ratings, lesson viewing
  (video/PDF/text), sequential lesson locking, quiz taking with retake/history review, course
  reviews, auto-issued certificates, and progress tracking. `flutter analyze` is clean and
  `flutter build apk --debug` compiles and installs cleanly (the shipped targets are
  Android/iOS — `flutter build web` is not configured for this project despite an earlier,
  inaccurate claim in this doc). See `mobile/README.md`.
- ⏭️ **Deliberately out of scope for now**: XP/points, day streaks, achievement badges,
  instructor-follow, and payment methods — all appear in the app's original design mockup but
  have no backend concept behind them yet and were not requested to be built.
