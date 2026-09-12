# Deploying MoreMore for free

Everything in the codebase is ready and already verified against your real Aiven database
(migrations ran successfully, schema confirmed correct). Two things left to do in your browser.

## Status

- ✅ Aiven PostgreSQL database — created, verified, migrated (all 15 tables + enum types confirmed)
- ✅ Render account — created and logged in
- ⬜ Deploy the blueprint (below)

## Step 1 — Deploy the blueprint

1. In Render, click **New** → **Blueprint**
2. Connect the `Khoeun-ratha/moremore` repo (via GitHub tab if not already connected)
3. Render reads `render.yaml` and shows two services: `moremore-backend` and `moremore-admin`
4. It will ask you to fill in one value — `DATABASE_URL`. Paste your Aiven **Service URI**, with
   the scheme changed from `postgres://` to `postgresql://` (everything else stays the same,
   including the `?sslmode=require` at the end)
5. Click **Apply**

No CA certificate step needed — the connection string's `sslmode=require` already handles
encryption for Postgres.

## Step 2 — Verify

1. Open `https://moremore-backend.onrender.com/health` — should show `{"status":"ok"}`
2. Open `https://moremore-admin.onrender.com` — should load the admin login page
3. Register a user through the app, then promote it to `super_admin` directly in the database
   (via Aiven's console → Query editor):
   ```sql
   UPDATE users SET role = 'super_admin' WHERE email = 'your-email@example.com';
   ```

## What's already done for you

- `render.yaml` — defines both services, auto-generates the JWT secret, wires CORS between them
- `backend/Dockerfile` — runs migrations automatically on every deploy, listens on Render's
  assigned port
- Backend switched from MySQL to PostgreSQL (`psycopg2`) to use Aiven's free Postgres tier —
  same permanence guarantee as their MySQL tier, no expiry
- Fixed two migrations that only worked on MySQL's enum handling and would have silently broken
  on Postgres (`gender` column, `super_admin` role addition) — caught by actually running the
  full migration chain against your live database before telling you to deploy
- File uploads (avatars, course covers, lesson videos/PDFs) go to Cloudinary instead of local
  disk, so they survive redeploys — see "File uploads" below for the one-time setup

## File uploads (Cloudinary)

Render's free web service has no persistent disk, so uploads can't live there — they're stored on
Cloudinary's free tier (25GB, no credit card) instead, which survives every redeploy.

1. Go to https://cloudinary.com → **Sign up** → continue with Google or GitHub
2. Your dashboard's home page shows three values under "API Environment variable" /
   "Product Environment credentials": **Cloud name**, **API Key**, **API Secret**
3. In Render, open **moremore-backend** → **Environment** tab, and add all three as environment
   variables: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
4. Save — Render redeploys automatically

## Mobile app

Not "hosted" in the same sense — build a release APK once the backend URL above is live:

```
flutter build apk --release --dart-define=API_BASE_URL=https://moremore-backend.onrender.com/api/v1
```

Then attach it to a GitHub Release on your existing repo (free, no new account) so people can
download and install it directly.
