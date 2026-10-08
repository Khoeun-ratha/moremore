"""Regression tests for admin edits/deletes once learners have real activity.

These all passed on SQLite only because it ignored foreign keys; with FK
enforcement on (as on PostgreSQL in production) each one used to fail with an
integrity error / 500.
"""

from tests.conftest import _register_and_login


def _course(client, admin_headers, title="Course"):
    return client.post(
        "/api/v1/courses",
        json={"title": title, "description": "", "category": "programming", "level": "beginner"},
        headers=admin_headers,
    ).json()


def _lesson(client, admin_headers, course_id, order_index, title="Lesson"):
    return client.post(
        f"/api/v1/courses/{course_id}/lessons",
        json={"title": title, "order_index": order_index, "content": ""},
        headers=admin_headers,
    ).json()


def _quiz_payload(question_text="Q1"):
    return {
        "title": "Quiz",
        "passing_score": 50,
        "questions": [
            {
                "text": question_text,
                "order_index": 1,
                "choices": [{"text": "right", "is_correct": True}, {"text": "wrong", "is_correct": False}],
            }
        ],
    }


def _pass_quiz(client, headers, lesson_id):
    quiz = client.get(f"/api/v1/lessons/{lesson_id}/quiz", headers=headers).json()
    answers = [
        {"question_id": q["id"], "choice_id": next(c["id"] for c in q["choices"] if c["is_correct"])}
        for q in quiz["questions"]
    ]
    resp = client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=headers)
    return quiz, resp


def test_admin_can_edit_quiz_after_learners_attempted_it(client, admin_headers, user_headers):
    course = _course(client, admin_headers)
    lesson = _lesson(client, admin_headers, course["id"], 0)
    client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=_quiz_payload(), headers=admin_headers)
    quiz, submit = _pass_quiz(client, user_headers, lesson["id"])
    assert submit.status_code == 200
    attempt_id = submit.json()["attempt_id"]

    resp = client.patch(f"/api/v1/quizzes/{quiz['id']}", json=_quiz_payload("Reworded"), headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json()["questions"][0]["text"] == "Reworded"

    # The learner's history survives the edit: the attempt and its score remain,
    # and opening it no longer crashes on the replaced questions.
    attempts = client.get(f"/api/v1/quizzes/{quiz['id']}/attempts", headers=user_headers).json()
    assert [a["id"] for a in attempts] == [attempt_id]
    detail = client.get(f"/api/v1/quizzes/attempts/{attempt_id}", headers=user_headers)
    assert detail.status_code == 200
    assert detail.json()["score"] == 1
    # ...and the lesson stays completed.
    assert client.get(f"/api/v1/lessons/{lesson['id']}", headers=user_headers).json()["completed"] is True


def test_admin_can_delete_quiz_with_attempts(client, admin_headers, user_headers):
    course = _course(client, admin_headers)
    lesson = _lesson(client, admin_headers, course["id"], 0)
    client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=_quiz_payload(), headers=admin_headers)
    quiz, _ = _pass_quiz(client, user_headers, lesson["id"])

    assert client.delete(f"/api/v1/quizzes/{quiz['id']}", headers=admin_headers).status_code == 204


def test_admin_can_delete_lesson_learners_completed(client, admin_headers, user_headers):
    course = _course(client, admin_headers)
    lesson = _lesson(client, admin_headers, course["id"], 0)
    client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=_quiz_payload(), headers=admin_headers)
    _pass_quiz(client, user_headers, lesson["id"])

    assert client.delete(f"/api/v1/lessons/{lesson['id']}", headers=admin_headers).status_code == 204
    assert client.get(f"/api/v1/lessons/{lesson['id']}", headers=user_headers).status_code == 404


def test_admin_can_delete_course_with_progress_reviews_and_games(client, admin_headers, user_headers):
    course = _course(client, admin_headers)
    lesson = _lesson(client, admin_headers, course["id"], 0)
    client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=_quiz_payload(), headers=admin_headers)
    _pass_quiz(client, user_headers, lesson["id"])  # progress + certificate
    client.put(
        f"/api/v1/courses/{course['id']}/reviews/me", json={"rating": 5, "comment": ""}, headers=user_headers
    )
    questions = client.get(
        "/api/v1/games/random-quiz", params={"course_id": course["id"]}, headers=user_headers
    ).json()
    game = client.post(
        "/api/v1/games/random-quiz/submit",
        params={"course_id": course["id"]},
        json={"answers": [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in questions]},
        headers=user_headers,
    )
    assert game.status_code == 200

    assert client.delete(f"/api/v1/courses/{course['id']}", headers=admin_headers).status_code == 204
    assert client.get(f"/api/v1/courses/{course['id']}", headers=user_headers).status_code == 404
    assert client.get("/api/v1/certificates/me", headers=user_headers).json() == []


def test_deleting_an_admin_keeps_the_courses_they_created(client, engine, admin_headers, super_admin_headers):
    course = _course(client, admin_headers, title="Owned by admin")
    admin_id = client.get("/api/v1/auth/me", headers=admin_headers).json()["id"]
    super_admin_id = client.get("/api/v1/auth/me", headers=super_admin_headers).json()["id"]

    assert client.delete(f"/api/v1/users/{admin_id}", headers=super_admin_headers).status_code == 204

    resp = client.get(f"/api/v1/courses/{course['id']}", headers=super_admin_headers)
    assert resp.status_code == 200
    assert resp.json()["created_by"] == super_admin_id


def test_admin_can_delete_a_learner_with_activity(client, admin_headers):
    learner = _register_and_login(client, "learner@example.com")
    course = _course(client, admin_headers)
    lesson = _lesson(client, admin_headers, course["id"], 0)
    client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=_quiz_payload(), headers=admin_headers)
    _pass_quiz(client, learner, lesson["id"])
    learner_id = client.get("/api/v1/auth/me", headers=learner).json()["id"]

    assert client.delete(f"/api/v1/users/{learner_id}", headers=admin_headers).status_code == 204


def test_lessons_unlock_in_order(client, admin_headers, user_headers):
    course = _course(client, admin_headers)
    first = _lesson(client, admin_headers, course["id"], 0, title="First")
    second = _lesson(client, admin_headers, course["id"], 1, title="Second")
    third = _lesson(client, admin_headers, course["id"], 2, title="Third")
    client.post(f"/api/v1/lessons/{third['id']}/quiz", json=_quiz_payload(), headers=admin_headers)

    # Skipping ahead is rejected, both for self-marked lessons and quiz lessons.
    assert client.post(f"/api/v1/lessons/{second['id']}/complete", headers=user_headers).status_code == 409
    _quiz, resp = _pass_quiz(client, user_headers, third["id"])
    assert resp.status_code == 409

    assert client.post(f"/api/v1/lessons/{first['id']}/complete", headers=user_headers).status_code == 200
    assert client.post(f"/api/v1/lessons/{second['id']}/complete", headers=user_headers).status_code == 200
    _quiz, resp = _pass_quiz(client, user_headers, third["id"])
    assert resp.status_code == 200
    assert resp.json()["passed"] is True

    # Re-doing an already-completed lesson stays allowed.
    assert client.post(f"/api/v1/lessons/{first['id']}/complete", headers=user_headers).status_code == 200
