#!/usr/bin/env bash
# Fixture: violates EIIS §4 marker convention (drift D-4) by writing
# bare appends to CLAUDE.md without <!-- eidolon:<name> --> markers.
set -u

EIDOLON_NAME="no-markers"
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

# Drift D-4: bare append to CLAUDE.md without markers.
if [ "$DRY_RUN" != "true" ]; then
  printf '\n# %s pointer\nSee %s/AGENTS.md\n' "$EIDOLON_NAME" "$TARGET" >> "CLAUDE.md"
fi

mkdir -p "${TARGET}"
cat > "${TARGET}/install.manifest.json" <<EOF
{
  "eidolon": "${EIDOLON_NAME}",
  "version": "${EIDOLON_VERSION}",
  "methodology": "NoMarkers",
  "installed_at": "2026-04-24T12:00:00Z",
  "target": "${TARGET}",
  "hosts_wired": ["claude-code"],
  "files_written": []
}
EOF
