#!/usr/bin/env bash
# Run Supabase/PostgreSQL migrations and RLS contracts without Docker or network.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_ROOT="${MEMORA_SUPABASE_TEST_ROOT:-$ROOT/backend/supabase}"
MIGRATIONS="$BACKEND_ROOT/migrations"
TESTS="$BACKEND_ROOT/tests"

mapfile_compat() {
  local directory="$1"
  find "$directory" -maxdepth 1 -type f -name '*.sql' -print 2>/dev/null | sort
}

if [[ ! -d "$MIGRATIONS" || ! -d "$TESTS" ]]; then
  echo "INFO: Slice 2 SQL contracts not implemented yet; RLS suite skipped."
  exit 0
fi

migration_files="$(mapfile_compat "$MIGRATIONS")"
test_files="$(mapfile_compat "$TESTS")"
if [[ -z "$migration_files" || -z "$test_files" ]]; then
  echo "INFO: Slice 2 SQL contracts not implemented yet; RLS suite skipped."
  exit 0
fi

for command_name in initdb pg_ctl createdb psql; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "ERROR: PostgreSQL command not found: $command_name" >&2
    exit 1
  }
done

RLS_TMP="$(mktemp -d "${TMPDIR:-/tmp}/memora-rls.XXXXXX")"
PGDATA="$RLS_TMP/data"
PGSOCKET="$RLS_TMP/socket"
PGPORT="$((54000 + ($$ % 1000)))"
mkdir -p "$PGSOCKET"

cleanup() {
  if [[ -s "$PGDATA/postmaster.pid" ]]; then
    pg_ctl -D "$PGDATA" -m fast -w stop >/dev/null 2>&1 || true
  fi
  if [[ "$RLS_TMP" == "${TMPDIR:-/tmp}"/memora-rls.* ]]; then
    rm -rf "$RLS_TMP"
  fi
}
trap cleanup EXIT INT TERM

initdb -D "$PGDATA" --auth=trust --no-locale --encoding=UTF8 >/dev/null
pg_ctl -D "$PGDATA" -o "-F -k $PGSOCKET -p $PGPORT" -w start >/dev/null
createdb -h "$PGSOCKET" -p "$PGPORT" memora_rls

PSQL=(psql -X -v ON_ERROR_STOP=1 -h "$PGSOCKET" -p "$PGPORT" -d memora_rls)

"${PSQL[@]}" <<'SQL'
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid
language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
SQL

while IFS= read -r sql_file; do
  [[ -n "$sql_file" ]] || continue
  echo "APPLY $(basename "$sql_file")"
  "${PSQL[@]}" -f "$sql_file"
done <<< "$migration_files"

while IFS= read -r sql_file; do
  [[ -n "$sql_file" ]] || continue
  echo "TEST  $(basename "$sql_file")"
  "${PSQL[@]}" -f "$sql_file"
done <<< "$test_files"

echo "RLS CONTRACT TESTS PASS"
