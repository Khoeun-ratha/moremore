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


def test_submit_random_quiz_reports_rank(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=2)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [{"question_id": q["id"], "choice_id": q["choices"][1]["id"]} for q in questions]

    resp = client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)
    result = resp.json()
    assert result["rank"] == 1  # first and only player so far


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


def test_leaderboard_requires_auth(client):
    resp = client.get("/api/v1/games/leaderboard")
    assert resp.status_code == 401


def test_leaderboard_empty_when_nobody_has_played(client, user_headers):
    resp = client.get("/api/v1/games/leaderboard", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_leaderboard_ranks_by_best_percentage_per_user(client, admin_headers, user_headers):
    from tests.conftest import _register_and_login

    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=4)

    other_headers = _register_and_login(client, "other-player@example.com")

    def play(headers, n_correct):
        questions = client.get("/api/v1/games/random-quiz", headers=headers).json()
        answers = []
        for i, q in enumerate(questions):
            correct_choice = next(c for c in q["choices"] if c["is_correct"])
            wrong_choice = next(c for c in q["choices"] if not c["is_correct"])
            choice = correct_choice if i < n_correct else wrong_choice
            answers.append({"question_id": q["id"], "choice_id": choice["id"]})
        return client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=headers).json()

    low_score = play(user_headers, n_correct=1)  # 25%
    high_score = play(other_headers, n_correct=3)  # 75%
    assert high_score["percentage"] > low_score["percentage"]

    resp = client.get("/api/v1/games/leaderboard", headers=user_headers)
    assert resp.status_code == 200
    board = resp.json()
    assert len(board) == 2
    assert board[0]["percentage"] == high_score["percentage"]
    assert board[0]["rank"] == 1
    assert board[1]["percentage"] == low_score["percentage"]
    assert board[1]["rank"] == 2
    assert {entry["full_name"] for entry in board} == {"Test User"}  # conftest registers all as "Test User"


def test_submit_random_quiz_rank_drops_after_being_overtaken(client, admin_headers, user_headers):
    from tests.conftest import _register_and_login

    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=4)

    other_headers = _register_and_login(client, "other-player@example.com")

    def play(headers, n_correct):
        questions = client.get("/api/v1/games/random-quiz", headers=headers).json()
        answers = []
        for i, q in enumerate(questions):
            correct_choice = next(c for c in q["choices"] if c["is_correct"])
            wrong_choice = next(c for c in q["choices"] if not c["is_correct"])
            choice = correct_choice if i < n_correct else wrong_choice
            answers.append({"question_id": q["id"], "choice_id": choice["id"]})
        return client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=headers).json()

    first = play(user_headers, n_correct=2)  # 50%
    assert first["rank"] == 1

    second = play(other_headers, n_correct=4)  # 100% — overtakes
    assert second["rank"] == 1

    # the first player's own rank has now dropped to 2nd
    board = client.get("/api/v1/games/leaderboard", headers=user_headers).json()
    assert board[0]["rank"] == 1 and board[0]["percentage"] == 100.0
    assert board[1]["rank"] == 2 and board[1]["percentage"] == 50.0


def test_admin_list_game_attempts_requires_admin(client, user_headers):
    resp = client.get("/api/v1/games/admin/attempts", headers=user_headers)
    assert resp.status_code == 403


def test_admin_list_game_attempts_shows_every_user(client, admin_headers, user_headers):
    from tests.conftest import _register_and_login

    course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=2)

    other_headers = _register_and_login(client, "other-player@example.com")

    for headers in (user_headers, other_headers):
        questions = client.get(f"/api/v1/games/random-quiz?course_id={course['id']}", headers=headers).json()
        answers = [{"question_id": q["id"], "choice_id": q["choices"][1]["id"]} for q in questions]
        client.post(
            f"/api/v1/games/random-quiz/submit?course_id={course['id']}",
            json={"answers": answers},
            headers=headers,
        )

    resp = client.get("/api/v1/games/admin/attempts", headers=admin_headers)
    assert resp.status_code == 200
    page = resp.json()
    assert page["total"] == 2
    assert len(page["items"]) == 2
    assert page["items"][0]["user_email"] in ("user@example.com", "other-player@example.com")
    assert page["items"][0]["course_title"] == "Intro to Python"


def test_admin_list_game_attempts_filters_by_search(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=1)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in questions]
    client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)

    resp = client.get("/api/v1/games/admin/attempts?q=nonexistent", headers=admin_headers)
    assert resp.json()["total"] == 0

    resp = client.get("/api/v1/games/admin/attempts?q=user@example.com", headers=admin_headers)
    assert resp.json()["total"] == 1


def test_admin_delete_game_attempt_requires_admin(client, user_headers):
    resp = client.delete("/api/v1/games/admin/attempts/1", headers=user_headers)
    assert resp.status_code == 403


def test_admin_delete_game_attempt_404_when_missing(client, admin_headers):
    resp = client.delete("/api/v1/games/admin/attempts/999", headers=admin_headers)
    assert resp.status_code == 404


def test_admin_delete_game_attempt_removes_it_from_leaderboard(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=1)

    questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
    answers = [{"question_id": q["id"], "choice_id": q["choices"][0]["id"]} for q in questions]
    client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)

    attempts = client.get("/api/v1/games/admin/attempts", headers=admin_headers).json()["items"]
    attempt_id = attempts[0]["id"]

    resp = client.delete(f"/api/v1/games/admin/attempts/{attempt_id}", headers=admin_headers)
    assert resp.status_code == 204

    board = client.get("/api/v1/games/leaderboard", headers=admin_headers).json()
    assert board == []


def test_leaderboard_keeps_only_best_round_per_user(client, admin_headers, user_headers):
    _course, lesson = _create_course_and_lesson(client, admin_headers)
    _create_quiz(client, admin_headers, lesson["id"], n_questions=4)

    def play(n_correct):
        questions = client.get("/api/v1/games/random-quiz", headers=user_headers).json()
        answers = []
        for i, q in enumerate(questions):
            correct_choice = next(c for c in q["choices"] if c["is_correct"])
            wrong_choice = next(c for c in q["choices"] if not c["is_correct"])
            choice = correct_choice if i < n_correct else wrong_choice
            answers.append({"question_id": q["id"], "choice_id": choice["id"]})
        client.post("/api/v1/games/random-quiz/submit", json={"answers": answers}, headers=user_headers)

    for n_correct in (1, 4, 2):  # worst, best, middling
        play(n_correct)

    board = client.get("/api/v1/games/leaderboard", headers=user_headers).json()
    assert len(board) == 1  # one row despite three rounds
    assert board[0]["score"] == 4
    assert board[0]["total"] == 4
    assert board[0]["percentage"] == 100.0
