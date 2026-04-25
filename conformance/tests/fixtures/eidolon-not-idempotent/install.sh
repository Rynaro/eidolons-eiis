#!/usr/bin/env bash
# Fixture: violates EIIS §5 (idempotency). Each run unconditionally
# appends to AGENTS.md without any marker convention or guard, so a
# re-run produces non-byte-identical output. Also has multiple
# non-deterministic substitutions (date used in two places).
set -u

EIDOLON_NAME="not-idempotent"
EIDOLON_VERSION="0.1.0"
TARGET="./.eidolons/${EIDOLON_NAME}"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]
  --target DIR
  --hosts LIST
  --force
  --dry-run
  --non-interactive
  --manifest-only
  --shared-dispatch
  --no-shared-dispatch
  --version
  -h, --help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --hosts) HOSTS="$2"; shift 2 ;;
    --shared-dispatch) shift ;;
    --no-shared-dispatch) shift ;;
    --force) FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    --manifest-only) MANIFEST_ONLY=true; shift ;;
    --version) echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 2 ;;
  esac
done

# §5 violation: bare append to AGENTS.md, no markers, no idempotency guard.
NOW1="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
NOW2="$(date -u +"%s")"
printf '\n# Installed at %s (run id %s)\n' "$NOW1" "$NOW2" >> "AGENTS.md"

mkdir -p "${TARGET}"
echo "{}" > "${TARGET}/state.json"
