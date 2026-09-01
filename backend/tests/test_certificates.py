def _create_course(client, admin_headers, title="Intro to Python", category="programming"):
    resp = client.post(
        "/api/v1/courses",
        json={"title": title, "description": "", "category": category, "level": "beginner"},
        headers=admin_headers,
    )
    return resp.json()


def _create_lesson(client, admin_headers, course_id, title, order_index):
    return client.post(
        f"/api/v1/courses/{course_id}/lessons",
        json={"title": title, "order_index": order_index, "content": ""},
        headers=admin_headers,
    ).json()


def test_no_certificate_before_course_complete(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    _create_lesson(client, admin_headers, course["id"], "Lesson 2", 2)

    resp = client.get("/api/v1/certificates/me", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_certificate_issued_when_all_lessons_complete(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson1 = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    lesson2 = _create_lesson(client, admin_headers, course["id"], "Lesson 2", 2)

    resp = client.post(f"/api/v1/lessons/{lesson1['id']}/complete", headers=user_headers)
    assert resp.status_code == 200

    # only one of two lessons done — no certificate yet
    assert client.get("/api/v1/certificates/me", headers=user_headers).json() == []

    client.post(f"/api/v1/lessons/{lesson2['id']}/complete", headers=user_headers)

    resp = client.get("/api/v1/certificates/me", headers=user_headers)
    assert resp.status_code == 200
    certs = resp.json()
    assert len(certs) == 1
    assert certs[0]["course_id"] == course["id"]
    assert certs[0]["course_title"] == course["title"]
    assert certs[0]["certificate_number"].startswith("CERT-")


def test_certificate_issued_only_once(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)

    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    first = client.get("/api/v1/certificates/me", headers=user_headers).json()

    # completing again (e.g. re-marking) must not issue a second certificate
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    second = client.get("/api/v1/certificates/me", headers=user_headers).json()

    assert len(first) == 1
    assert first == second


def test_certificate_via_quiz_completion(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    quiz = client.post(
        f"/api/v1/lessons/{lesson['id']}/quiz",
        json={
            "title": "Quiz",
            "passing_score": 50,
            "questions": [
                {
                    "text": "Q1",
                    "order_index": 1,
                    "choices": [{"text": "wrong", "is_correct": False}, {"text": "right", "is_correct": True}],
                }
            ],
        },
        headers=admin_headers,
    ).json()

    choice_id = quiz["questions"][0]["choices"][1]["id"]
    client.post(
        f"/api/v1/quizzes/{quiz['id']}/submit",
        json={"answers": [{"question_id": quiz["questions"][0]["id"], "choice_id": choice_id}]},
        headers=user_headers,
    )

    certs = client.get("/api/v1/certificates/me", headers=user_headers).json()
    assert len(certs) == 1
    assert certs[0]["course_id"] == course["id"]


def test_certificates_are_per_user(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)

    assert client.get("/api/v1/certificates/me", headers=admin_headers).json() == []


def test_progress_surfaces_certificate_number_once_issued(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)

    cert_number = client.get("/api/v1/certificates/me", headers=user_headers).json()[0]["certificate_number"]

    progress = client.get(f"/api/v1/progress/courses/{course['id']}", headers=user_headers).json()
    assert progress["certificate_number"] == cert_number


def test_admin_can_list_all_certificates(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)

    resp = client.get("/api/v1/certificates", headers=admin_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    item = body["items"][0]
    assert item["course_id"] == course["id"]
    assert item["course_title"] == course["title"]
    assert "user_full_name" in item and "user_email" in item


def test_admin_certificate_list_search_filters(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers, title="Searchable Course")
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)

    assert client.get("/api/v1/certificates", params={"q": "Searchable"}, headers=admin_headers).json()["total"] == 1
    assert client.get("/api/v1/certificates", params={"q": "no-such-thing"}, headers=admin_headers).json()["total"] == 0


def test_non_admin_cannot_list_certificates(client, user_headers):
    assert client.get("/api/v1/certificates", headers=user_headers).status_code == 403


def test_admin_can_get_certificate_detail(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    cert_id = client.get("/api/v1/certificates", headers=admin_headers).json()["items"][0]["id"]

    resp = client.get(f"/api/v1/certificates/{cert_id}", headers=admin_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["course_id"] == course["id"]
    assert body["course_title"] == course["title"]
    assert "user_full_name" in body and "user_email" in body


def test_certificate_detail_404_when_missing(client, admin_headers):
    assert client.get("/api/v1/certificates/999999", headers=admin_headers).status_code == 404


def test_non_admin_cannot_get_certificate_detail(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    lesson = _create_lesson(client, admin_headers, course["id"], "Lesson 1", 1)
    client.post(f"/api/v1/lessons/{lesson['id']}/complete", headers=user_headers)
    cert_id = client.get("/api/v1/certificates", headers=admin_headers).json()["items"][0]["id"]

    assert client.get(f"/api/v1/certificates/{cert_id}", headers=user_headers).status_code == 403
