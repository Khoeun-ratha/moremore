def _create_course_and_lesson(client, admin_headers, title="Intro to Python"):
    course = client.post(
        "/api/v1/courses",
        json={"title": title, "description": "", "category": "programming", "level": "beginner"},
        headers=admin_headers,
    ).json()
    lesson = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()
    return course, lesson


def _create_quiz(client, admin_headers, lesson_id, n_questions=2):
    payload = {
        "title": "Variables Quiz",
        "passing_score": 70,
        "questions": [
            {
                "text": f"Question {i}",
                "order_index": i,
                "choices": [
                    {"text": "wrong", "is_correct": False},
                    {"text": "right", "is_correct": True},
                ],
            }
            for i in range(n_questions)
        ],
    }
    resp = client.post(f"/api/v1/lessons/{lesson_id}/quiz", json=payload, headers=admin_headers)
    assert resp.status_code == 201
    return resp.json()


def test_random_quiz_requires_auth(client):
    resp = client.get("/api/v1/games/random-quiz")
    assert resp.status_code == 401


def test_random_quiz_404_when_no_questions_exist(client, user_headers):
    resp = client.get("/api/v1/games/random-quiz", headers=user_headers)
    assert resp.status_code == 404


def test_random_quiz_reveals_correct_choice_for_instant_feedback(client, admin_headers, user_headers):
    """Unlike a lesson quiz, the game is casual practice — it reveals the
    correct choice up front so the client can give instant right/wrong
    feedback per question, no round trip needed."""
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=2)

    resp = client.get("/api/v1/games/random-quiz", headers=user_headers)
    assert resp.status_code == 200
    questions = resp.json()
    assert len(questions) == 2
    for q in questions:
        assert sum(1 for c in q["choices"] if c["is_correct"]) == 1


def test_random_quiz_respects_count_cap(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=5)

    resp = client.get("/api/v1/games/random-quiz?count=2", headers=user_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_random_quiz_scoped_to_course(client, admin_headers, user_headers):
    course_a, lesson_a = _create_course_and_lesson(client, admin_headers, title="Course A")
    _create_quiz(client, admin_headers, lesson_a["id"], n_questions=2)
    course_b, lesson_b = _create_course_and_lesson(client, admin_headers, title="Course B")
    _create_quiz(client, admin_headers, lesson_b["id"], n_questions=3)

    resp = client.get(f"/api/v1/games/random-quiz?course_id={course_b['id']}&count=10", headers=user_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 3

    resp = client.get(f"/api/v1/games/random-quiz?course_id={course_a['id']}&count=10", headers=user_headers)
    assert len(resp.json()) == 2


def test_submit_random_quiz_scores_and_records_attempt(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=2)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [{"question_id": q["id"], "choice_id": q["choices"][1]["id"]} for q in questions]

    resp = client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)
    assert resp.status_code == 200
    result = resp.json()
    assert result["score"] == 2
    assert result["total"] == 2
    assert result["percentage"] == 100.0
    assert len(result["answers"]) == 2

    history = client.get("/api/v1/games/my-attempts", headers=user_headers).json()
    assert len(history) == 1
    assert history[0]["score"] == 2
    assert history[0]["total"] == 2


def test_submit_random_quiz_partial_score(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=2)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [
        {"question_id": questions[0]["id"], "choice_id": questions[0]["choices"][1]["id"]},
        {"question_id": questions[1]["id"], "choice_id": questions[1]["choices"][0]["id"]},
    ]

    resp = client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)
    result = resp.json()
    assert result["score"] == 1
    assert result["percentage"] == 50.0


def test_my_attempts_only_shows_own_history(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=1)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in questions]
    client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)

    admin_history = client.get("/api/v1/games/my-attempts", headers=admin_headers).json()
    assert admin_history == []
