# Deploying MoreMore for free

Everything in the codebase is ready. Three copy-paste steps left, and they need to happen in
your browser because they create accounts tied to you — I can't do this part, but everything
after it, I already have wired up.

## Step 1 — Free MySQL database (Aiven, ~2 min)

1. Go to https://aiven.io/free-mysql-database
2. Click **Sign up** → **Continue with GitHub** → **Authorize**
3. Click **Create service** → pick **MySQL** → select the **Free** plan → **Create service**
4. Wait ~1 minute for it to start, then open the service page
5. Copy two things and save them somewhere for step 3:
   - **Service URI** (starts with `mysql://...`)
   - **CA Certificate** (starts with `-----BEGIN CERTIFICATE-----`)

## Step 2 — Render account (~1 min)

1. Go to https://render.com
2. Click **Get Started** → **GitHub** → **Authorize**

That's the entire signup. No card, no config yet.

## Step 3 — Deploy the blueprint (~2 min)

1. In Render, click **New** → **Blueprint**
2. Connect the `Khoeun-ratha/moremore` repo
3. Render reads `render.yaml` (already in the repo root) and shows two services:
   `moremore-backend` and `moremore-admin`
4. Before clicking **Apply**, it'll ask you to fill in `DATABASE_URL` (marked as a secret) — paste
   the Aiven **Service URI** from step 1, but change the start of it from `mysql://` to
   `mysql+pymysql://`
5. Click **Apply**

## Step 4 — Add the CA certificate (~1 min)

The backend needs Aiven's CA certificate to connect over TLS. Render's free plan has no shell
access, so this uses Render's **Secret Files** feature instead — just pasting into a dashboard
field, nothing to run:

1. Open the **moremore-backend** service → **Environment** tab
2. Scroll to **Secret Files** → **Add Secret File**
3. Filename: `aiven-ca.pem`
4. Contents: paste the CA Certificate text from step 1
5. Save — Render mounts it at `/etc/secrets/aiven-ca.pem` automatically (already wired up via
   `DATABASE_SSL_CA_PATH` in `render.yaml`) and redeploys the service on its own

## Step 5 — Verify

1. Open `https://moremore-backend.onrender.com/health` — should show `{"status":"ok"}`
2. Open `https://moremore-admin.onrender.com` — should load the admin login page
3. Log in with an admin account (or register one, then promote it via direct DB access if this
   is the very first user)

## What's already done for you

- `render.yaml` — defines both services, auto-generates the JWT secret, wires CORS between them
- `backend/Dockerfile` — runs migrations automatically on every deploy, listens on Render's
  assigned port
- `backend/app/db/session.py` + `alembic/env.py` — support Aiven's required TLS via
  `DATABASE_SSL_CA_PATH`

## Known limitation (free tier)

Render's free web service has no persistent disk — any avatar/video/PDF uploaded through the app
gets wiped on every redeploy. Fine to launch with; ask me to wire up free object storage
(Cloudinary) later if this becomes a real problem.

## Mobile app

Not "hosted" in the same sense — build a release APK once the backend URL above is live:

```
flutter build apk --release --dart-define=API_BASE_URL=https://moremore-backend.onrender.com/api/v1
```

Then attach it to a GitHub Release on your existing repo (free, no new account) so people can
download and install it directly.
