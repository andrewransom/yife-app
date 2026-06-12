#!/usr/bin/env bash
set -euo pipefail

psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  --set=ON_ERROR_STOP=1 \
  --file=supabase/tests/rls_smoke.sql
