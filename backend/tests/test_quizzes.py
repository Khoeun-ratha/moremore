def _create_course_and_lesson(client, admin_headers):
    course = client.post(
        "/api/v1/courses",
        json={"title": "Intro to Python", "description": "", "category": "programming", "level": "beginner"},
        headers=admin_headers,
    ).json()
    lesson = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()
    return course, lesson


def _create_quiz(client, admin_headers, lesson_id, passing_score=70):
    payload = {
        "title": "Variables Quiz",
        "passing_score": passing_score,
        "questions": [
            {
                "text": "What keyword defines a variable in Python?",
                "order_index": 1,
                "choices": [
                    {"text": "var", "is_correct": False},
                    {"text": "no keyword needed", "is_correct": True},
                ],
            },
            {
                "text": "Which is a valid variable name?",
                "order_index": 2,
                "choices": [
                    {"text": "2cool", "is_correct": False},
                    {"text": "cool2", "is_correct": True},
                ],
            },
        ],
    }
    resp = client.post(f"/api/v1/lessons/{lesson_id}/quiz", json=payload, headers=admin_headers)
    assert resp.status_code == 201
    return resp.json()


def test_non_admin_cannot_create_quiz(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    resp = client.post(
        f"/api/v1/lessons/{lesson['id']}/quiz",
        json={"title": "x", "passing_score": 50, "questions": []},
        headers=user_headers,
    )
    assert resp.status_code == 403


def test_quiz_requires_exactly_one_correct_choice(client, admin_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    payload = {
        "title": "Bad Quiz",
        "passing_score": 50,
        "questions": [
            {
                "text": "Q1",
                "order_index": 1,
                "choices": [{"text": "A", "is_correct": True}, {"text": "B", "is_correct": True}],
            }
        ],
    }
    resp = client.post(f"/api/v1/lessons/{lesson['id']}/quiz", json=payload, headers=admin_headers)
    assert resp.status_code == 422


def test_get_quiz_hides_correct_answer(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"])

    resp = client.get(f"/api/v1/lessons/{lesson['id']}/quiz", headers=user_headers)
    assert resp.status_code == 200
    question = resp.json()["questions"][0]
    assert "is_correct" not in question["choices"][0]


def test_admin_full_quiz_view_exposes_answers(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"])

    forbidden = client.get(f"/api/v1/quizzes/{quiz['id']}/full", headers=user_headers)
    assert forbidden.status_code == 403

    resp = client.get(f"/api/v1/quizzes/{quiz['id']}/full", headers=admin_headers)
    assert resp.status_code == 200
    question = resp.json()["questions"][0]
    assert "is_correct" in question["choices"][0]
    assert sum(1 for c in question["choices"] if c["is_correct"]) == 1


def test_submit_all_correct_passes_and_completes_lesson(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = []
    for q in quiz["questions"]:
        # second choice was always the correct one by construction in _create_quiz
        answers.append({"question_id": q["id"], "choice_id": q["choices"][1]["id"]})

    resp = client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers)
    assert resp.status_code == 200
    result = resp.json()
    assert result["score"] == 2
    assert result["total"] == 2
    assert result["percentage"] == 100.0
    assert result["passed"] is True

    progress = client.get(f"/api/v1/progress/courses/{_course['id']}", headers=user_headers).json()
    assert progress["completed_lessons"] == 1
    assert progress["total_lessons"] == 1


def test_submit_all_wrong_fails(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in quiz["questions"]]
    resp = client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers)
    result = resp.json()
    assert result["score"] == 0
    assert result["passed"] is False


def test_submit_partial_credit_below_threshold(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = [
        {"question_id": quiz["questions"][0]["id"], "choice_id": quiz["questions"][0]["choices"][1]["id"]},
        {"question_id": quiz["questions"][1]["id"], "choice_id": quiz["questions"][1]["choices"][0]["id"]},
    ]
    resp = client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers)
    result = resp.json()
    assert result["score"] == 1
    assert result["percentage"] == 50.0
    assert result["passed"] is False


def test_attempt_history_recorded(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in quiz["questions"]]
    client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers)
    client.post(f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers)

    resp = client.get(f"/api/v1/quizzes/{quiz['id']}/attempts", headers=user_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_attempt_detail_lets_owner_review_past_attempt(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = [{"question_id": q["id"], "choice_id": q["choices"][1]["id"]} for q in quiz["questions"]]
    submit_result = client.post(
        f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers
    ).json()

    resp = client.get(f"/api/v1/quizzes/attempts/{submit_result['attempt_id']}", headers=user_headers)
    assert resp.status_code == 200
    detail = resp.json()
    assert detail["score"] == 2
    assert detail["passed"] is True
    assert len(detail["answers"]) == 2


def test_attempt_detail_hidden_from_other_users(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    quiz = _create_quiz(client, admin_headers, lesson["id"], passing_score=70)

    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in quiz["questions"]]
    submit_result = client.post(
        f"/api/v1/quizzes/{quiz['id']}/submit", json={"answers": answers}, headers=user_headers
    ).json()

    resp = client.get(f"/api/v1/quizzes/attempts/{submit_result['attempt_id']}", headers=admin_headers)
    assert resp.status_code == 404
