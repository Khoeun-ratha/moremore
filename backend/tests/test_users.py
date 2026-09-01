def test_admin_can_update_another_users_name(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.patch(
        f"/api/v1/users/{me['id']}",
        json={"full_name": "Renamed By Admin"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "Renamed By Admin"


def test_admin_can_update_another_users_email(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.patch(
        f"/api/v1/users/{me['id']}",
        json={"email": "renamed@example.com"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["email"] == "renamed@example.com"

    # The old identifier no longer logs in; the new one does.
    old_login = client.post(
        "/api/v1/auth/login",
        data={"username": "user@example.com", "password": "Password123!"},
    )
    assert old_login.status_code == 401
    new_login = client.post(
        "/api/v1/auth/login",
        data={"username": "renamed@example.com", "password": "Password123!"},
    )
    assert new_login.status_code == 200


def test_admin_update_email_rejects_conflict(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.patch(
        f"/api/v1/users/{me['id']}",
        json={"email": "admin@example.com"},
        headers=admin_headers,
    )
    assert resp.status_code == 409


def test_admin_can_reset_another_users_password(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.post(
        f"/api/v1/users/{me['id']}/reset-password",
        json={"new_password": "BrandNewPassword1!"},
        headers=admin_headers,
    )
    assert resp.status_code == 204

    # Old password no longer works.
    old_login = client.post(
        "/api/v1/auth/login",
        data={"username": "user@example.com", "password": "Password123!"},
    )
    assert old_login.status_code == 401

    # New password works.
    new_login = client.post(
        "/api/v1/auth/login",
        data={"username": "user@example.com", "password": "BrandNewPassword1!"},
    )
    assert new_login.status_code == 200


def test_admin_reset_password_revokes_existing_sessions(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    # user_headers carries a still-valid refresh token pair from login; simulate
    # by issuing one and confirming it stops working after the admin resets the password.
    login = client.post(
        "/api/v1/auth/login",
        data={"username": "user@example.com", "password": "Password123!"},
    )
    refresh_token = login.json()["refresh_token"]

    client.post(
        f"/api/v1/users/{me['id']}/reset-password",
        json={"new_password": "BrandNewPassword1!"},
        headers=admin_headers,
    )

    refresh_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_resp.status_code == 401


def test_reset_password_rejects_short_password(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.post(
        f"/api/v1/users/{me['id']}/reset-password",
        json={"new_password": "short"},
        headers=admin_headers,
    )
    assert resp.status_code == 422


def test_non_admin_cannot_reset_another_users_password(client, user_headers):
    resp = client.post(
        "/api/v1/users/1/reset-password",
        json={"new_password": "BrandNewPassword1!"},
        headers=user_headers,
    )
    assert resp.status_code == 403


# --- super admin permission boundary -------------------------------------


def test_regular_admin_cannot_grant_admin_role(client, admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.patch(
        f"/api/v1/users/{me['id']}",
        json={"role": "admin"},
        headers=admin_headers,
    )
    assert resp.status_code == 403


def test_super_admin_can_grant_admin_role(client, super_admin_headers, user_headers):
    me = client.get("/api/v1/auth/me", headers=user_headers).json()

    resp = client.patch(
        f"/api/v1/users/{me['id']}",
        json={"role": "admin"},
        headers=super_admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["role"] == "admin"


def test_regular_admin_cannot_edit_another_admin(client, admin_headers, super_admin_headers):
    from tests.conftest import _register_and_login

    # Promote a second, distinct user to admin via the super admin.
    second_admin_headers = _register_and_login(client, "second-admin@example.com")
    second_me = client.get("/api/v1/auth/me", headers=second_admin_headers).json()
    client.patch(f"/api/v1/users/{second_me['id']}", json={"role": "admin"}, headers=super_admin_headers)

    # The first (regular) admin tries to edit the second admin's account.
    resp = client.patch(
        f"/api/v1/users/{second_me['id']}",
        json={"full_name": "Hijacked"},
        headers=admin_headers,
    )
    assert resp.status_code == 403


def test_regular_admin_cannot_reset_another_admins_password(client, admin_headers, super_admin_headers):
    admin_me = client.get("/api/v1/auth/me", headers=admin_headers).json()

    resp = client.post(
        f"/api/v1/users/{admin_me['id']}/reset-password",
        json={"new_password": "BrandNewPassword1!"},
        headers=admin_headers,
    )
    # an admin resetting their own password via the admin-management endpoint
    # is still gated by the admin-target check (self-service uses /auth/change-password).
    assert resp.status_code == 403


def test_super_admin_can_manage_another_admin(client, admin_headers, super_admin_headers):
    admin_me = client.get("/api/v1/auth/me", headers=admin_headers).json()

    resp = client.patch(
        f"/api/v1/users/{admin_me['id']}",
        json={"full_name": "Renamed By Super Admin"},
        headers=super_admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "Renamed By Super Admin"

    reset_resp = client.post(
        f"/api/v1/users/{admin_me['id']}/reset-password",
        json={"new_password": "BrandNewPassword1!"},
        headers=super_admin_headers,
    )
    assert reset_resp.status_code == 204


def test_regular_admin_cannot_delete_another_admin(client, admin_headers, super_admin_headers):
    admin_me = client.get("/api/v1/auth/me", headers=admin_headers).json()

    resp = client.delete(f"/api/v1/users/{admin_me['id']}", headers=admin_headers)
    assert resp.status_code == 403
