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


def test_upload_image_succeeds(client, admin_headers, monkeypatch):
    """Files are stored on Cloudinary (persistent, unlike Render's disk) —
    the real network call is mocked so tests don't depend on live credentials."""
    import app.services.file_service as file_service_module

    monkeypatch.setattr(
        file_service_module.cloudinary.uploader,
        "upload_large",
        lambda buffer, **kwargs: {"secure_url": "https://res.cloudinary.com/demo/image/upload/fake.png"},
    )

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
    assert body["url"] == "https://res.cloudinary.com/demo/image/upload/fake.png"


def test_upload_video_uses_video_resource_type(client, admin_headers, monkeypatch):
    import app.services.file_service as file_service_module

    captured_kwargs = {}

    def fake_upload_large(buffer, **kwargs):
        captured_kwargs.update(kwargs)
        return {"secure_url": "https://res.cloudinary.com/demo/video/upload/fake.mp4"}

    monkeypatch.setattr(file_service_module.cloudinary.uploader, "upload_large", fake_upload_large)

    video_bytes = b"0123456789" * 100
    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "video"},
        files={"file": ("clip.mp4", io.BytesIO(video_bytes), "video/mp4")},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["url"] == "https://res.cloudinary.com/demo/video/upload/fake.mp4"
    assert body["size_bytes"] == len(video_bytes)
    assert captured_kwargs["resource_type"] == "video"


def test_upload_pdf_uses_raw_resource_type(client, admin_headers, monkeypatch):
    import app.services.file_service as file_service_module

    captured_kwargs = {}

    def fake_upload_large(buffer, **kwargs):
        captured_kwargs.update(kwargs)
        return {"secure_url": "https://res.cloudinary.com/demo/raw/upload/fake.pdf"}

    monkeypatch.setattr(file_service_module.cloudinary.uploader, "upload_large", fake_upload_large)

    resp = client.post(
        "/api/v1/files/upload",
        params={"kind": "pdf"},
        files={"file": ("notes.pdf", io.BytesIO(b"%PDF-1.4 fake"), "application/pdf")},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert captured_kwargs["resource_type"] == "raw"
