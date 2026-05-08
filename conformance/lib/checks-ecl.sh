# shellcheck shell=bash
# EIIS §4.6 — ECL composition (v1.2+). Sourced by check.sh.
#
# ECL composition is OPTIONAL. An Eidolon MAY ship a repo-root `ECL_VERSION`
# file. If it does, the checker validates:
#
#   E0  ECL_VERSION format matches ^[0-9]+\.[0-9]+(\.[0-9]+)?$  (WARN)
#   E1  If install.manifest.json includes ecl_version_emitted, it matches
#       ECL_VERSION                                               (WARN)
#
# Both checks are warn-only in v1.2 — they do not contribute to exit code 2
# (MUST fail). Absence of ECL_VERSION is OK and produces a single informational
# ok record.
#
# Bash 3.2 compatible. No external deps beyond grep and jq (jq is already a
# hard dep of check.sh for manifest parsing).
#
# Public function: eiis_check_ecl <repo-dir-absolute> <target-version>

eiis_check_ecl() {
  local dir="$1"
  local target_version="$2"

  # Skip ECL checks for pre-v1.2 Eidolons.
  case "$target_version" in
    1.0|1.0.*|1|1.1|1.1.*)
      record "E0" "MUST" "ok" \
        "ECL checks skipped (target EIIS_VERSION ${target_version} predates v1.2)"
      return
      ;;
  esac

  local ecl_ver_file="$dir/ECL_VERSION"
  if [ ! -f "$ecl_ver_file" ]; then
    # §4.6.1.3 — absence is fine for Eidolons that do not emit ECL artefacts.
    record "E0" "MUST" "ok" \
      "ECL_VERSION not present (ECL composition is OPTIONAL in v1.2)"
    return
  fi

  # Read the declared ECL version (first line, strip whitespace; bash 3.2 ok).
  local ecl_ver
  ecl_ver="$(head -n 1 "$ecl_ver_file" | tr -d '[:space:]')"

  # E0 — format check (warn-only per §4.6.5).
  if printf '%s' "$ecl_ver" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
    record "E0" "MUST" "ok" \
      "ECL_VERSION='${ecl_ver}' format valid (^[0-9]+\\.[0-9]+(\\.[0-9]+)?\\$)"
  else
    record "E0" "MUST" "warn" \
      "ECL_VERSION format invalid (§4.6.1.1)" \
      "value '${ecl_ver}' does not match ^[0-9]+\\.[0-9]+(\\.[0-9]+)?\\$; correct or remove ECL_VERSION"
    # Still continue to E1 with whatever value we have.
  fi

  # E1 — ecl_version_emitted ↔ ECL_VERSION consistency (warn-only per §4.6.5).
  # Only checked if install.manifest.json exists and contains the field.
  local manifest_file="$dir/install.manifest.json"
  if [ ! -f "$manifest_file" ]; then
    # No manifest present yet (e.g. skeleton before first install); skip E1.
    return
  fi

  # Use jq to extract ecl_version_emitted; produce empty string if absent.
  # Requires jq (already a hard dep of check.sh).
  local emitted
  emitted="$(jq -r '.ecl_version_emitted // empty' "$manifest_file" 2>/dev/null)"
  if [ -z "$emitted" ]; then
    # Field absent — no mismatch possible.
    record "E1" "MUST" "ok" \
      "ecl_version_emitted not present in manifest (field is OPTIONAL per §3.7)"
    return
  fi

  if [ "$emitted" = "$ecl_ver" ]; then
    record "E1" "MUST" "ok" \
      "ecl_version_emitted='${emitted}' matches ECL_VERSION (§4.6.4.1)"
  else
    record "E1" "MUST" "warn" \
      "ecl_version_emitted mismatch (§4.6.4.2)" \
      "manifest ecl_version_emitted='${emitted}' != ECL_VERSION='${ecl_ver}'; rebuild manifest"
  fi
}
