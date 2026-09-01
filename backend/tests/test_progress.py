def _setup_course_with_two_lessons(client, admin_headers):
    course = client.post(
        "/api/v1/courses",
        json={"title": "Intro to Python", "description": "", "category": "programming", "level": "beginner"},
        headers=admin_headers,
    ).json()
    lesson1 = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()
    lesson2 = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Loops", "order_index": 2, "content": ""},
        headers=admin_headers,
    ).json()
    return course, lesson1, lesson2


def _create_quiz(client, admin_headers, lesson_id):
    payload = {
        "title": "Quiz",
        "passing_score": 50,
        "questions": [
            {
                "text": "Q1",
                "order_index": 1,
                "choices": [{"text": "wrong", "is_correct": False}, {"text": "right", "is_correct": True}],
            }
        ],
    }
    return client.post(f"/api/v1/lessons/{lesson_id}/quiz", json=payload, headers=admin_headers).json()


def test_progress_zero_before_any_quiz(client, admin_headers, user_headers):
    course, _lesson1, _lesson2 = _setup_course_with_two_lessons(client, admin_headers)

    resp = client.get(f"/api/v1/progress/courses/{course['id']}", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json() == {
        "course_id": course["id"],
        "course_title": "Intro to Python",
        "total_lessons": 2,
        "completed_lessons": 0,
        "percentage": 0.0,
        "certificate_number": None,
    }


def test_progress_updates_after_passing_quiz(client, admin_headers, user_headers):
    course, lesson1, _lesson2 = _setup_course_with_two_lessons(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson1["id"])

    choice_id = quiz["questions"][0]["choices"][1]["id"]
    client.post(
        f"/api/v1/quizzes/{quiz['id']}/submit",
        json={"answers": [{"question_id": quiz["questions"][0]["id"], "choice_id": choice_id}]},
        headers=user_headers,
    )

    resp = client.get(f"/api/v1/progress/courses/{course['id']}", headers=user_headers)
    body = resp.json()
    assert body["completed_lessons"] == 1
    assert body["percentage"] == 50.0

    overall = client.get("/api/v1/progress/me", headers=user_headers).json()
    course_entry = next(c for c in overall["courses"] if c["course_id"] == course["id"])
    assert course_entry["completed_lessons"] == 1


def test_progress_requires_auth(client):
    assert client.get("/api/v1/progress/me").status_code == 401
