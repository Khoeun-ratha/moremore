def _create_course(client, admin_headers):
    resp = client.post(
        "/api/v1/courses",
        json={"title": "Intro to Python", "description": "", "category": "programming", "level": "beginner"},
        headers=admin_headers,
    )
    return resp.json()


def test_create_and_list_lessons(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)

    resp = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={
            "title": "Variables",
            "order_index": 1,
            "content": "Learn about variables",
            "video_url": "https://example.com/video.mp4",
            "file_url": "https://example.com/slides.pdf",
        },
        headers=admin_headers,
    )
    assert resp.status_code == 201
    lesson = resp.json()
    assert lesson["has_quiz"] is False

    resp = client.get(f"/api/v1/courses/{course['id']}/lessons", headers=user_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 1
    assert resp.json()[0]["title"] == "Variables"


def test_non_admin_cannot_create_lesson(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    resp = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=user_headers,
    )
    assert resp.status_code == 403


def test_mark_lesson_without_quiz_complete(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()

    resp = client.get(f"/api/v1/lessons/{lesson['id']}", headers=user_headers)
    assert resp.json()["completed"] is False

    resp = client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json()["completed"] is True

    resp = client.get(f"/api/v1/lessons/{lesson['id']}", headers=user_headers)
    assert resp.json()["completed"] is True


def test_cannot_manually_complete_lesson_with_quiz(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()
    client.post(
        f"/api/v1/lessons/{lesson['id']}/quiz",
        json={
            "title": "Quiz",
            "passing_score": 50,
            "questions": [
                {
                    "text": "Q1",
                    "order_index": 1,
                    "choices": [{"text": "A", "is_correct": True}, {"text": "B", "is_correct": False}],
                }
            ],
        },
        headers=admin_headers,
    )

    resp = client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    assert resp.status_code == 409


def test_update_and_delete_lesson(client, admin_headers):
    course = _create_course(client, admin_headers)
    lesson = client.post(
        f"/api/v1/courses/{course['id']}/lessons",
        json={"title": "Variables", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()

    resp = client.patch(
        f"/api/v1/lessons/{lesson['id']}", json={"title": "Variables and Types"}, headers=admin_headers
    )
    assert resp.status_code == 200
    assert resp.json()["title"] == "Variables and Types"

    resp = client.delete(f"/api/v1/lessons/{lesson['id']}", headers=admin_headers)
    assert resp.status_code == 204

    resp = client.get(f"/api/v1/lessons/{lesson['id']}", headers=admin_headers)
    assert resp.status_code == 404
