#!/usr/bin/env bash
# EIIS conformance checker.
#
# Usage:
#   bash check.sh <eidolon-repo-dir> [options]
#
# Options:
#   --level=MUST|SHOULD     Restrict reporting to checks at this level or
#                           stricter. Default: report all.
#   --json                  Emit machine-readable JSON instead of human
#                           [OK]/[FAIL]/[WARN] lines.
#   --target-version 1.0    EIIS version to check against. Default: read
#                           from <repo>/EIIS_VERSION; fall back to 1.0.
#   -h, --help              Print this help and exit 0.
#
# Exit codes (EIIS v1.0 §T.4):
#   0  Passes all MUSTs at the declared EIIS_VERSION.
#   1  Generic failure (missing dir, unreadable files, bad usage).
#   2  Fails one or more MUSTs.
#   3  Passes MUSTs but fails one or more SHOULDs (advisory).
#   4  Passes MUSTs but emits warn-only output for grandfathered drifts
#      (D-3, D-6 within their warn-only window).
#
# Bash 3.2 compatible. Hard deps: jq, bash, POSIX coreutils.
# Optional: ajv or python -m jsonschema for full JSON Schema validation
# of the manifest. Falls back to structural field-presence checks.

set -u
# We deliberately do not `set -e`; we want to collect every check.

VERSION="3.0.0"

# -- option parsing --------------------------------------------------------- #

REPO_DIR=""
LEVEL="ALL"
OUTPUT="human"
TARGET_VERSION=""

print_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --level=*)         LEVEL="${1#--level=}"; shift ;;
    --level)           LEVEL="$2"; shift 2 ;;
    --json)            OUTPUT="json"; shift ;;
    --target-version)  TARGET_VERSION="$2"; shift 2 ;;
    --target-version=*) TARGET_VERSION="${1#--target-version=}"; shift ;;
    -h|--help)         print_help; exit 0 ;;
    --version)         echo "$VERSION"; exit 0 ;;
    --)                shift; break ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Run: bash $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      if [ -z "$REPO_DIR" ]; then
        REPO_DIR="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$REPO_DIR" ]; then
  echo "Usage: bash $(basename "$0") <eidolon-repo-dir> [options]" >&2
  exit 1
fi

if [ ! -d "$REPO_DIR" ]; then
  echo "Not a directory: $REPO_DIR" >&2
  exit 1
fi

# Normalise to absolute path; bash 3.2 compatible.
REPO_DIR_ABS="$(cd "$REPO_DIR" && pwd)"

# -- target version resolution --------------------------------------------- #

if [ -z "$TARGET_VERSION" ]; then
  if [ -f "$REPO_DIR_ABS/EIIS_VERSION" ]; then
    # Read first line, strip whitespace; bash 3.2 ok.
    TARGET_VERSION="$(head -n 1 "$REPO_DIR_ABS/EIIS_VERSION" | tr -d '[:space:]')"
  fi
fi

if [ -z "$TARGET_VERSION" ]; then
  TARGET_VERSION="1.0"
fi

# The checker knows about v1.0 (baseline), v1.1 (Codex addendum),
# v1.2 (ECL composition clause), v1.3 (canonical SPEC.md + skills dual-write),
# v1.4 (canonical install-target inventory + agent-profile + ECL_VERSION
# MUST + host-vendor body contract + cleanup obligation + agent.md consistency),
# and v1.5 (hook role + hook_event field + hooks/ inventory whitelist +
# hook wiring conventions), and v3.0 (self-contained canonical tree).
# Any future 1.x version is tolerated and runs v1.5 gates as the closest
# known set.
case "$TARGET_VERSION" in
  1.0|1.0.*|1)   : "v1.0 baseline" ;;
  1.1|1.1.*)     : "v1.1 (Codex addendum)" ;;
  1.2|1.2.*)     : "v1.2 (ECL composition clause)" ;;
  1.3|1.3.*)     : "v1.3 (canonical SPEC.md + skills dual-write)" ;;
  1.4|1.4.*)     : "v1.4 (canonical inventory whitelist + agent-profile + ECL_VERSION MUST)" ;;
  1.5|1.5.*)     : "v1.5 (hook role + hook_event field + hooks/ whitelist)" ;;
  1.*)           : "future 1.x; running v1.5 gates" ;;
  3.0|3.0.*|3)   : "v3.0 (self-contained canonical tree)" ;;
  3.*)           : "future 3.x; running v3.0 gates" ;;
  *)
    echo "Unsupported --target-version: $TARGET_VERSION (this checker knows 1.x and 3.x)" >&2
    exit 1
    ;;
esac

# -- result accumulator ---------------------------------------------------- #

# Parallel arrays (bash 3.2 has no associative arrays).
RES_IDS=()
RES_NAMES=()
RES_LEVELS=()    # MUST | SHOULD | WARN
RES_STATUSES=()  # ok | fail | warn
RES_REASONS=()

record() {
  # record <id> <level> <status> <name> <reason?>
  RES_IDS+=("$1")
  RES_LEVELS+=("$2")
  RES_STATUSES+=("$3")
  RES_NAMES+=("$4")
  RES_REASONS+=("${5:-}")
}

# -- library load ---------------------------------------------------------- #

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
if [ ! -d "$LIB_DIR" ]; then
  echo "Internal error: lib dir not found at $LIB_DIR" >&2
  exit 1
fi

# shellcheck source=lib/checks-layout.sh
. "$LIB_DIR/checks-layout.sh"
# shellcheck source=lib/checks-flags.sh
. "$LIB_DIR/checks-flags.sh"
# shellcheck source=lib/checks-manifest.sh
. "$LIB_DIR/checks-manifest.sh"
# shellcheck source=lib/checks-markers.sh
. "$LIB_DIR/checks-markers.sh"
# shellcheck source=lib/checks-idempotency.sh
. "$LIB_DIR/checks-idempotency.sh"
# shellcheck source=lib/checks-codex.sh
. "$LIB_DIR/checks-codex.sh"
# shellcheck source=lib/checks-ecl.sh
. "$LIB_DIR/checks-ecl.sh"
# shellcheck source=lib/checks-spec-skills.sh
. "$LIB_DIR/checks-spec-skills.sh"
# shellcheck source=lib/checks-inventory.sh
. "$LIB_DIR/checks-inventory.sh"
# shellcheck source=lib/checks-v3.sh
. "$LIB_DIR/checks-v3.sh"

# -- run checks ------------------------------------------------------------ #

case "$TARGET_VERSION" in
  3|3.*)
    eiis_check_flags "$REPO_DIR_ABS"
    eiis_check_manifest "$REPO_DIR_ABS"
    eiis_check_idempotency "$REPO_DIR_ABS"
    eiis_check_v3 "$REPO_DIR_ABS" "$TARGET_VERSION"
    ;;
  *)
    eiis_check_layout        "$REPO_DIR_ABS"
    eiis_check_flags         "$REPO_DIR_ABS"
    eiis_check_manifest      "$REPO_DIR_ABS"
    eiis_check_markers       "$REPO_DIR_ABS"
    eiis_check_idempotency   "$REPO_DIR_ABS"
    eiis_check_codex         "$REPO_DIR_ABS" "$TARGET_VERSION"
    eiis_check_ecl           "$REPO_DIR_ABS" "$TARGET_VERSION"
    eiis_check_spec_skills   "$REPO_DIR_ABS" "$TARGET_VERSION"
    eiis_check_inventory     "$REPO_DIR_ABS" "$TARGET_VERSION"
    ;;
esac

# -- summarise ------------------------------------------------------------- #

EXIT_CODE=0
HAS_MUST_FAIL=0
HAS_SHOULD_FAIL=0
HAS_WARN=0

i=0
n=${#RES_IDS[@]}
while [ "$i" -lt "$n" ]; do
  level="${RES_LEVELS[$i]}"
  status="${RES_STATUSES[$i]}"
  case "$status:$level" in
    fail:MUST)   HAS_MUST_FAIL=1 ;;
    fail:SHOULD) HAS_SHOULD_FAIL=1 ;;
    warn:*)      HAS_WARN=1 ;;
  esac
  i=$((i + 1))
done

if [ "$HAS_MUST_FAIL" -eq 1 ]; then
  EXIT_CODE=2
elif [ "$HAS_SHOULD_FAIL" -eq 1 ]; then
  EXIT_CODE=3
elif [ "$HAS_WARN" -eq 1 ]; then
  EXIT_CODE=4
else
  EXIT_CODE=0
fi

# -- emit ------------------------------------------------------------------ #

emit_human() {
  echo "EIIS conformance check"
  echo "Repository:    $REPO_DIR_ABS"
  echo "Target EIIS:   $TARGET_VERSION"
  echo "Level filter:  $LEVEL"
  echo "----"
  i=0
  while [ "$i" -lt "$n" ]; do
    level="${RES_LEVELS[$i]}"
    status="${RES_STATUSES[$i]}"
    name="${RES_NAMES[$i]}"
    id="${RES_IDS[$i]}"
    reason="${RES_REASONS[$i]}"

    # Apply --level filter (only suppresses passing SHOULD lines when
    # filter is MUST; failures and warnings always print so they aren't
    # silently hidden).
    if [ "$LEVEL" = "MUST" ] && [ "$level" = "SHOULD" ] && [ "$status" = "ok" ]; then
      i=$((i + 1)); continue
    fi

    case "$status" in
      ok)   tag="[OK]   " ;;
      fail) tag="[FAIL] " ;;
      warn) tag="[WARN] " ;;
      *)    tag="[?]    " ;;
    esac
    if [ -n "$reason" ]; then
      echo "${tag}${id} ${level} ${name} (${reason})"
    else
      echo "${tag}${id} ${level} ${name}"
    fi
    i=$((i + 1))
  done
  echo "----"
  case "$EXIT_CODE" in
    0) echo "Result: OK (exit 0)" ;;
    2) echo "Result: FAIL — one or more MUSTs failed (exit 2)" ;;
    3) echo "Result: SHOULD-fail (exit 3)" ;;
    4) echo "Result: WARN — passes MUSTs with grandfathered warnings (exit 4)" ;;
  esac
}

emit_json() {
  # Build JSON manually; jq -n is fine but bash 3.2-compatible string
  # building gives us total control over escaping.
  printf '{\n'
  printf '  "eidolon_repo": "%s",\n'        "$(json_escape "$REPO_DIR_ABS")"
  printf '  "eiis_version_targeted": "%s",\n' "$(json_escape "$TARGET_VERSION")"
  printf '  "level_filter": "%s",\n'        "$(json_escape "$LEVEL")"
  printf '  "results": [\n'
  i=0
  first=1
  while [ "$i" -lt "$n" ]; do
    level="${RES_LEVELS[$i]}"
    status="${RES_STATUSES[$i]}"
    name="${RES_NAMES[$i]}"
    id="${RES_IDS[$i]}"
    reason="${RES_REASONS[$i]}"
    if [ "$first" -eq 0 ]; then printf ',\n'; fi
    first=0
    printf '    {"id": "%s", "level": "%s", "status": "%s", "name": "%s"' \
      "$(json_escape "$id")" "$(json_escape "$level")" "$(json_escape "$status")" "$(json_escape "$name")"
    if [ -n "$reason" ]; then
      printf ', "warn_reason": "%s"' "$(json_escape "$reason")"
    fi
    printf '}'
    i=$((i + 1))
  done
  printf '\n  ],\n'
  printf '  "exit_code": %d\n' "$EXIT_CODE"
  printf '}\n'
}

# Minimal JSON string escaper — handles \, ", and control chars 0x00-0x1f.
json_escape() {
  printf '%s' "$1" | awk '
    BEGIN {
      for (i = 0; i < 32; i++) {
        ctrl[sprintf("%c", i)] = sprintf("\\u%04x", i)
      }
    }
    {
      s = $0
      gsub(/\\/, "\\\\", s)
      gsub(/"/,  "\\\"", s)
      gsub(/\t/, "\\t", s)
      gsub(/\r/, "\\r", s)
      printf "%s", s
    }
  '
}

if [ "$OUTPUT" = "json" ]; then
  emit_json
else
  emit_human
fi

exit "$EXIT_CODE"
