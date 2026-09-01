def _phone_for(email: str) -> str:
    """Deterministic, unique-enough fake phone number for a given test email."""
    return f"+1{abs(hash(email)) % 10_000_000_000:010d}"


def test_register_and_login(client):
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": "alice@example.com",
            "phone": _phone_for("alice@example.com"),
            "password": "Password123!",
            "full_name": "Alice",
        },
    )
    assert resp.status_code == 201
    assert resp.json()["email"] == "alice@example.com"
    assert resp.json()["role"] == "user"

    resp = client.post(
        "/api/v1/auth/login", data={"username": "alice@example.com", "password": "Password123!"}
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body and "refresh_token" in body


def test_login_with_phone_number(client):
    phone = _phone_for("gina@example.com")
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "gina@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Gina",
        },
    )

    resp = client.post("/api/v1/auth/login", data={"username": phone, "password": "Password123!"})
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body and "refresh_token" in body


def test_duplicate_phone_registration_rejected(client):
    phone = _phone_for("henry@example.com")
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "henry@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Henry",
        },
    )
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": "someone-else@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Someone Else",
        },
    )
    assert resp.status_code == 409


def test_duplicate_registration_rejected(client):
    payload = {
        "email": "bob@example.com",
        "phone": _phone_for("bob@example.com"),
        "password": "Password123!",
        "full_name": "Bob",
    }
    assert client.post("/api/v1/auth/register", json=payload).status_code == 201
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 409


def test_login_wrong_password_rejected(client):
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "carol@example.com",
            "phone": _phone_for("carol@example.com"),
            "password": "Password123!",
            "full_name": "Carol",
        },
    )
    resp = client.post(
        "/api/v1/auth/login", data={"username": "carol@example.com", "password": "wrong-password"}
    )
    assert resp.status_code == 401


def test_me_requires_auth(client):
    assert client.get("/api/v1/auth/me").status_code == 401


def test_me_returns_current_user(client, user_headers):
    resp = client.get("/api/v1/auth/me", headers=user_headers)
    assert resp.status_code == 200
    assert resp.json()["email"] == "user@example.com"


def test_refresh_rotates_token(client):
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "dave@example.com",
            "phone": _phone_for("dave@example.com"),
            "password": "Password123!",
            "full_name": "Dave",
        },
    )
    login = client.post(
        "/api/v1/auth/login", data={"username": "dave@example.com", "password": "Password123!"}
    ).json()

    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]})
    assert refreshed.status_code == 200
    new_tokens = refreshed.json()
    assert new_tokens["access_token"] != login["access_token"]

    # old refresh token was rotated out and should no longer work
    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]})
    assert reused.status_code == 401


def test_update_profile_name(client, user_headers):
    resp = client.patch("/api/v1/auth/me", json={"full_name": "New Name"}, headers=user_headers)
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "New Name"


def test_update_profile_phone_gender_and_email(client, user_headers):
    new_phone = _phone_for("user-updated@example.com")
    resp = client.patch(
        "/api/v1/auth/me",
        json={
            "phone": new_phone,
            "gender": "female",
            "email": "user-updated@example.com",
        },
        headers=user_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["phone"] == new_phone
    assert body["gender"] == "female"
    assert body["email"] == "user-updated@example.com"

    # unrelated fields (full_name) are left untouched by a partial update
    assert body["full_name"] == "Test User"


def test_update_profile_rejects_duplicate_email(client, user_headers):
    phone = _phone_for("taken@example.com")
    client.post(
        "/api/v1/auth/register",
        json={"email": "taken@example.com", "phone": phone, "password": "Password123!", "full_name": "Taken"},
    )
    resp = client.patch("/api/v1/auth/me", json={"email": "taken@example.com"}, headers=user_headers)
    assert resp.status_code == 409


def test_update_profile_rejects_duplicate_phone(client, user_headers):
    phone = _phone_for("taken-phone@example.com")
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "taken-phone@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Taken Phone",
        },
    )
    resp = client.patch("/api/v1/auth/me", json={"phone": phone}, headers=user_headers)
    assert resp.status_code == 409


def test_upload_avatar(client, user_headers):
    # save_upload only checks extension + non-empty size, so real image bytes aren't required.
    fake_png_bytes = b"not-a-real-png-but-non-empty"
    resp = client.post(
        "/api/v1/auth/me/avatar",
        files={"file": ("avatar.png", fake_png_bytes, "image/png")},
        headers=user_headers,
    )
    assert resp.status_code == 200
    avatar_url = resp.json()["avatar_url"]
    assert avatar_url is not None
    assert avatar_url.startswith("/media/images/")

    # persisted — GET /me reflects it
    me = client.get("/api/v1/auth/me", headers=user_headers)
    assert me.json()["avatar_url"] == avatar_url


def test_change_password_requires_correct_current_password(client, user_headers):
    resp = client.post(
        "/api/v1/auth/change-password",
        json={"current_password": "wrong", "new_password": "NewPassword123!"},
        headers=user_headers,
    )
    assert resp.status_code == 401


def test_change_password_then_login_with_new_password(client, user_headers):
    resp = client.post(
        "/api/v1/auth/change-password",
        json={"current_password": "Password123!", "new_password": "NewPassword123!"},
        headers=user_headers,
    )
    assert resp.status_code == 204

    login = client.post(
        "/api/v1/auth/login", data={"username": "user@example.com", "password": "NewPassword123!"}
    )
    assert login.status_code == 200


def test_forgot_password_does_not_reveal_unknown_phone(client):
    resp = client.post("/api/v1/auth/forgot-password", json={"phone": "+19999999999"})
    assert resp.status_code == 200
    assert resp.json()["dev_code"] is None


def test_forgot_password_reset_flow(client, monkeypatch):
    phone = _phone_for("frank@example.com")
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "frank@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Frank",
        },
    )

    captured = {}

    def fake_send(to_phone, code):
        captured["phone"] = to_phone
        captured["code"] = code

    monkeypatch.setattr("app.services.auth_service.send_password_reset_sms", fake_send)

    resp = client.post("/api/v1/auth/forgot-password", json={"phone": phone})
    assert resp.status_code == 200
    assert captured["phone"] == phone
    code = captured["code"]
    assert resp.json()["dev_code"] == code

    # the OTP can be checked before committing to a new password
    verify_resp = client.post("/api/v1/auth/verify-reset-code", json={"phone": phone, "code": code})
    assert verify_resp.status_code == 204

    reset_resp = client.post(
        "/api/v1/auth/reset-password",
        json={"phone": phone, "code": code, "new_password": "BrandNew123!"},
    )
    assert reset_resp.status_code == 204

    # old password no longer works, new one does
    assert client.post(
        "/api/v1/auth/login", data={"username": "frank@example.com", "password": "Password123!"}
    ).status_code == 401
    assert client.post(
        "/api/v1/auth/login", data={"username": "frank@example.com", "password": "BrandNew123!"}
    ).status_code == 200

    # the code is single-use
    reused = client.post(
        "/api/v1/auth/reset-password",
        json={"phone": phone, "code": code, "new_password": "AnotherOne123!"},
    )
    assert reused.status_code == 400


def test_verify_reset_code_rejects_wrong_code(client):
    phone = _phone_for("iris@example.com")
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "iris@example.com",
            "phone": phone,
            "password": "Password123!",
            "full_name": "Iris",
        },
    )
    client.post("/api/v1/auth/forgot-password", json={"phone": phone})

    resp = client.post("/api/v1/auth/verify-reset-code", json={"phone": phone, "code": "000000"})
    assert resp.status_code == 400


def test_reset_password_invalid_code_rejected(client):
    resp = client.post(
        "/api/v1/auth/reset-password",
        json={"phone": "+10000000000", "code": "123456", "new_password": "Whatever123!"},
    )
    assert resp.status_code == 400


def test_logout_revokes_refresh_token(client):
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "erin@example.com",
            "phone": _phone_for("erin@example.com"),
            "password": "Password123!",
            "full_name": "Erin",
        },
    )
    login = client.post(
        "/api/v1/auth/login", data={"username": "erin@example.com", "password": "Password123!"}
    ).json()

    logout_resp = client.post("/api/v1/auth/logout", json={"refresh_token": login["refresh_token"]})
    assert logout_resp.status_code == 204

    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]})
    assert refreshed.status_code == 401
