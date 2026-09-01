def _create_course(client, admin_headers, title="Intro to Python", category="programming"):
    resp = client.post(
        "/api/v1/courses",
        json={"title": title, "description": "", "category": category, "level": "beginner"},
        headers=admin_headers,
    )
    return resp.json()


def _phone_for(email: str) -> str:
    """Deterministic, unique-enough fake phone number for a given test email."""
    return f"+1{abs(hash(email)) % 10_000_000_000:010d}"


def _register_and_login(client, email):
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "phone": _phone_for(email), "password": "Password123!", "full_name": "Reviewer"},
    )
    resp = client.post("/api/v1/auth/login", data={"username": email, "password": "Password123!"})
    tokens = resp.json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_course_has_no_rating_before_any_review(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    resp = client.get(f"/api/v1/courses/{course['id']}", headers=user_headers)
    assert resp.json()["average_rating"] is None
    assert resp.json()["review_count"] == 0


def test_submit_review_and_see_it_on_course(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)

    resp = client.put(
        f"/api/v1/courses/{course['id']}/reviews/me",
        json={"rating": 5, "comment": "Great course!"},
        headers=user_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["rating"] == 5
    assert body["comment"] == "Great course!"
    assert body["reviewer_name"] == "Test User"

    course_resp = client.get(f"/api/v1/courses/{course['id']}", headers=user_headers).json()
    assert course_resp["average_rating"] == 5.0
    assert course_resp["review_count"] == 1

    reviews = client.get(f"/api/v1/courses/{course['id']}/reviews", headers=user_headers).json()
    assert len(reviews) == 1
    assert reviews[0]["rating"] == 5


def test_resubmitting_review_updates_it_instead_of_duplicating(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)

    client.put(
        f"/api/v1/courses/{course['id']}/reviews/me", json={"rating": 2, "comment": "meh"}, headers=user_headers
    )
    client.put(
        f"/api/v1/courses/{course['id']}/reviews/me",
        json={"rating": 4, "comment": "actually pretty good"},
        headers=user_headers,
    )

    reviews = client.get(f"/api/v1/courses/{course['id']}/reviews", headers=user_headers).json()
    assert len(reviews) == 1
    assert reviews[0]["rating"] == 4
    assert reviews[0]["comment"] == "actually pretty good"


def test_average_rating_across_multiple_reviewers(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    other_headers = _register_and_login(client, "other-reviewer@example.com")

    client.put(f"/api/v1/courses/{course['id']}/reviews/me", json={"rating": 4}, headers=user_headers)
    client.put(f"/api/v1/courses/{course['id']}/reviews/me", json={"rating": 2}, headers=other_headers)

    resp = client.get(f"/api/v1/courses/{course['id']}", headers=user_headers).json()
    assert resp["average_rating"] == 3.0
    assert resp["review_count"] == 2

    listing = client.get("/api/v1/courses", headers=user_headers).json()
    listed_course = next(c for c in listing["items"] if c["id"] == course["id"])
    assert listed_course["average_rating"] == 3.0


def test_rating_out_of_range_rejected(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)
    resp = client.put(
        f"/api/v1/courses/{course['id']}/reviews/me", json={"rating": 6}, headers=user_headers
    )
    assert resp.status_code == 422
