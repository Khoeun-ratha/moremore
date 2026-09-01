import io


def test_non_admin_cannot_upload(client, user_headers):
    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "image"},
        files={"file": ("photo.png", io.BytesIO(b"fake-image-bytes"), "image/png")},
        headers=user_headers,
    )
    assert resp.status_code == 403


def test_upload_rejects_disallowed_extension(client, admin_headers):
    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "pdf"},
        files={"file": ("notes.exe", io.BytesIO(b"binary"), "application/octet-stream")},
        headers=admin_headers,
    )
    assert resp.status_code == 400


def test_upload_rejects_oversized_file(client, admin_headers, monkeypatch):
    from app.core import config as config_module

    monkeypatch.setattr(config_module.settings, "MAX_UPLOAD_SIZE_MB", 0.000001)

    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "image"},
        files={"file": ("photo.png", io.BytesIO(b"x" * 1024), "image/png")},
        headers=admin_headers,
    )
    assert resp.status_code == 413


def test_upload_image_succeeds_and_is_servable(client, admin_headers):
    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "image"},
        files={"file": ("photo.png", io.BytesIO(b"fake-image-bytes"), "image/png")},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["kind"] == "image"
    assert body["size_bytes"] == len(b"fake-image-bytes")

    served = client.get(body["url"])
    assert served.status_code == 200
    assert served.content == b"fake-image-bytes"


def test_upload_supports_range_requests_for_video(client, admin_headers):
    video_bytes = b"0123456789" * 100
    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "video"},
        files={"file": ("clip.mp4", io.BytesIO(video_bytes), "video/mp4")},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    url = resp.json()["url"]

    ranged = client.get(url, headers={"Range": "bytes=0-9"})
    assert ranged.status_code == 206
    assert ranged.content == b"0123456789"
