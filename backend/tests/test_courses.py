def _create_course(client, admin_headers, title="Intro to Python", category="programming"):
    resp = client.post(
        "/api/v1/courses",
        json={"title": title, "description": "Learn the basics", "category": category, "level": "beginner"},
        headers=admin_headers,
    )
    assert resp.status_code == 201
    return resp.json()


def test_non_admin_cannot_create_course(client, user_headers):
    resp = client.post(
        "/api/v1/courses",
        json={"title": "Hack", "description": "", "category": "x", "level": "beginner"},
        headers=user_headers,
    )
    assert resp.status_code == 403


def test_admin_can_create_and_fetch_course(client, admin_headers, user_headers):
    course = _create_course(client, admin_headers)

    resp = client.get(f"/api/v1/courses/{course['id']}", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json()["title"] == "Intro to Python"
    assert resp.json()["lesson_count"] == 0


def test_list_courses_requires_auth(client):
    assert client.get("/api/v1/courses").status_code == 401


def test_search_and_filter_courses(client, admin_headers, user_headers):
    _create_course(client, admin_headers, title="Intro to Python", category="programming")
    _create_course(client, admin_headers, title="Watercolor Painting", category="art")

    resp = client.get("/api/v1/courses", params={"q": "Python"}, headers=user_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    assert body["items"][0]["title"] == "Intro to Python"

    resp = client.get("/api/v1/courses", params={"category": "art"}, headers=user_headers)
    assert resp.json()["total"] == 1
    assert resp.json()["items"][0]["category"] == "art"


def test_recommended_requires_auth(client):
    assert client.get("/api/v1/courses/recommended").status_code == 401


def test_recommended_favors_engaged_category_and_excludes_completed(client, admin_headers, user_headers):
    course_a = _create_course(client, admin_headers, title="Python Basics", category="programming")
    lesson_a = client.post(
        f"/api/v1/courses/{course_a['id']}/lessons",
        json={"title": "Lesson", "order_index": 1, "content": ""},
        headers=admin_headers,
    ).json()
    course_b = _create_course(client, admin_headers, title="Advanced Python", category="programming")
    course_c = _create_course(client, admin_headers, title="Watercolor Painting", category="art")

    # complete course A entirely -> engaged with "programming", but course A itself is done
    client.post(f"/api/v1/lessons/{lesson_a['id']}/complete", headers=user_headers)

    resp = client.get("/api/v1/courses/recommended", headers=user_headers)
    assert resp.status_code == 200
    recommended_ids = {c["id"] for c in resp.json()}
    assert course_b["id"] in recommended_ids
    assert course_a["id"] not in recommended_ids
    assert course_c["id"] not in recommended_ids


def test_update_and_delete_course(client, admin_headers):
    course = _create_course(client, admin_headers)

    resp = client.patch(
        f"/api/v1/courses/{course['id']}", json={"title": "Intro to Python 2"}, headers=admin_headers
    )
    assert resp.status_code == 200
    assert resp.json()["title"] == "Intro to Python 2"

    resp = client.delete(f"/api/v1/courses/{course['id']}", headers=admin_headers)
    assert resp.status_code == 204

    resp = client.get(f"/api/v1/courses/{course['id']}", headers=admin_headers)
    assert resp.status_code == 404
