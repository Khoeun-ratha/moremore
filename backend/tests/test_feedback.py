def test_submit_feedback_and_see_it_in_my_list(client, user_headers):
    resp = client.post(
        "/api/v1/feedback",
        json={"type": "feedback", "subject": "Love the app", "message": "Just wanted to say thanks!"},
        headers=user_headers,
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["type"] == "feedback"
    assert body["status"] == "new"

    mine = client.get("/api/v1/feedback/me", headers=user_headers)
    assert mine.status_code == 200
    assert len(mine.json()) == 1
    assert mine.json()[0]["subject"] == "Love the app"


def test_submit_lesson_suggestion(client, user_headers):
    resp = client.post(
        "/api/v1/feedback",
        json={
            "type": "lesson_suggestion",
            "subject": "Advanced Python",
            "message": "Could you add a lesson on decorators and generators?",
        },
        headers=user_headers,
    )
    assert resp.status_code == 201
    assert resp.json()["type"] == "lesson_suggestion"


def test_submit_feedback_requires_subject_and_message(client, user_headers):
    resp = client.post(
        "/api/v1/feedback",
        json={"type": "feedback", "subject": "  ", "message": "hello"},
        headers=user_headers,
    )
    assert resp.status_code == 422


def test_regular_user_cannot_list_all_feedback(client, user_headers):
    resp = client.get("/api/v1/feedback", headers=user_headers)
    assert resp.status_code == 403


def test_admin_can_list_and_view_feedback(client, user_headers, admin_headers):
    client.post(
        "/api/v1/feedback",
        json={"type": "feedback", "subject": "Bug report", "message": "The quiz screen crashes."},
        headers=user_headers,
    )

    listed = client.get("/api/v1/feedback", headers=admin_headers)
    assert listed.status_code == 200
    body = listed.json()
    assert body["total"] == 1
    item = body["items"][0]
    assert item["subject"] == "Bug report"
    assert item["user_email"] == "user@example.com"

    detail = client.get(f"/api/v1/feedback/{item['id']}", headers=admin_headers)
    assert detail.status_code == 200
    assert detail.json()["message"] == "The quiz screen crashes."


def test_admin_can_update_feedback_status(client, user_headers, admin_headers):
    submitted = client.post(
        "/api/v1/feedback",
        json={"type": "feedback", "subject": "Idea", "message": "Add dark mode."},
        headers=user_headers,
    ).json()

    resp = client.patch(
        f"/api/v1/feedback/{submitted['id']}",
        json={"status": "reviewed"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "reviewed"

    # persisted
    detail = client.get(f"/api/v1/feedback/{submitted['id']}", headers=admin_headers)
    assert detail.json()["status"] == "reviewed"


def test_admin_can_filter_feedback_by_type_and_status(client, user_headers, admin_headers):
    client.post(
        "/api/v1/feedback",
        json={"type": "feedback", "subject": "General note", "message": "Nice job overall."},
        headers=user_headers,
    )
    suggestion = client.post(
        "/api/v1/feedback",
        json={"type": "lesson_suggestion", "subject": "Rust basics", "message": "Please add a Rust course."},
        headers=user_headers,
    ).json()
    client.patch(f"/api/v1/feedback/{suggestion['id']}", json={"status": "dismissed"}, headers=admin_headers)

    only_suggestions = client.get("/api/v1/feedback", params={"type": "lesson_suggestion"}, headers=admin_headers)
    assert only_suggestions.json()["total"] == 1
    assert only_suggestions.json()["items"][0]["subject"] == "Rust basics"

    only_dismissed = client.get("/api/v1/feedback", params={"status": "dismissed"}, headers=admin_headers)
    assert only_dismissed.json()["total"] == 1
    assert only_dismissed.json()["items"][0]["subject"] == "Rust basics"

    only_new = client.get("/api/v1/feedback", params={"status": "new"}, headers=admin_headers)
    assert only_new.json()["total"] == 1
    assert only_new.json()["items"][0]["subject"] == "General note"
