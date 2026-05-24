#!/usr/bin/env bash
# Runs cancel_order + partial_cancel_order SQL regression tests (BEGIN/ROLLBACK).
#
# Requires a Postgres URL where migrations 001–019 are applied (Supabase-style
# schema, including auth.users FK used by the tests).
#
# Usage:
#   export DATABASE_URL='postgresql://...'
#   ./scripts/run_cancel_and_partial_cancel_sql_tests.sh
#
# If `psql` is not on PATH (Homebrew libpq is keg-only):
#   export PSQL=/opt/homebrew/opt/libpq/bin/psql
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URI="${1:-${DATABASE_URL:-}}"
if [[ -z "$URI" ]]; then
  echo "usage: DATABASE_URL=... $0   OR   $0 'postgresql://...'" >&2
  exit 1
fi
PSQL_BIN="${PSQL:-psql}"
"$PSQL_BIN" "$URI" -v ON_ERROR_STOP=1 -f "$ROOT/supabase/tests/cancel_order_test.sql"
"$PSQL_BIN" "$URI" -v ON_ERROR_STOP=1 -f "$ROOT/supabase/tests/partial_cancel_order_test.sql"
echo "OK: cancel_order_test.sql + partial_cancel_order_test.sql"
