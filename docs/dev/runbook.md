# Local Dev Runbook

## 1) Environment setup

- Start from `.env.example`:

```bash
cd /Users/andrew/dev/yife-app
cp .env.example .env
```

- Keep `./.env` local-only.  
- `NUXT_PUBLIC_SUPABASE_URL` and `NUXT_PUBLIC_SUPABASE_ANON_KEY` are filled from local Supabase CLI output (below).

## 2) Start local Supabase

```bash
pnpm supabase:start
```

- This starts local API at port `54321`, Postgres at port `54322`, and Studio on `54323` (per `supabase/config.toml`).
- Get current runtime values with:

```bash
supabase status
```

## 3) Reset and seed database

Run this whenever you need a clean local DB:

```bash
pnpm supabase:reset
```

- This performs local migration reset and seed reload (`db.seed.sql`), per this repo’s `supabase/config.toml`.
- Then keep the same server running and continue.
- Recommended after pulling DB/schema updates.

## 4) Run local dev server

```bash
pnpm dev
```

- App runs at `http://127.0.0.1:3055`.
- For agent/dev secondary flows: `pnpm dev:agent` (port `3056`).

## 5) Local test login credentials

- Default seeded local test account:

```text
Email: e2e@yife.local
Password: password123
```

- Create/verify this account after Supabase start (and any reset) with:

```bash
pnpm e2e:seed-user
```

- You can override these credentials in `.env` if needed:

```bash
E2E_AUTH_EMAIL=
E2E_AUTH_PASSWORD=
```

## 6) Local database credentials

From the default Supabase local config and CLI defaults:

- Supabase API URL: `http://127.0.0.1:54321`
- Database host: `127.0.0.1`
- Database port: `54322`
- Database user: `postgres`
- Database password: `postgres`
- Database name: `postgres`
- Connection string:

```text
postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

- Use `supabase status` for local `anon` and `service_role` keys:
  - `anon key`
  - `service_role key`

### Suggested `.env` values

```bash
NUXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NUXT_PUBLIC_SUPABASE_ANON_KEY=<paste anon key from `supabase status`>
SUPABASE_SERVICE_ROLE_KEY=<paste service_role key from `supabase status`>
```
