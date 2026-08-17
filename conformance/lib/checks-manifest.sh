# shellcheck shell=bash
# EIIS §3 — install.manifest.json schema checks. Sourced by check.sh.
#
# Strategy: static analysis only. We do not execute install.sh; instead we
# look for a sample manifest in the repo. Two locations in priority order:
#
#   1. <repo>/examples/install.manifest.json (if the repo ships one)
#   2. <repo>/.eidolons/<eidolon>/install.manifest.json (if a previous
#      install left one in the repo)
#
# When no sample manifest is present, we record a single advisory entry
# (M0) noting that runtime behaviour was not verified. This is the
# expected case for a fresh clone of an Eidolon repo — most don't ship a
# sample manifest. The behavioural validation is handled by the
# per-Eidolon CI workflow that actually runs install.sh.
#
# Public function: eiis_check_manifest <repo-dir-absolute>

eiis_check_manifest() {
  local dir="$1"
  local manifest=""
  local found_via=""

  if [ -f "$dir/examples/install.manifest.json" ]; then
    manifest="$dir/examples/install.manifest.json"
    found_via="examples/install.manifest.json"
  else
    # Look for any install.manifest.json under .eidolons/, .test/, or test
    # output directories, but bound the search depth to keep this fast.
    local candidate
    candidate="$(find "$dir" -maxdepth 4 -name install.manifest.json -type f 2>/dev/null | head -n 1)"
    if [ -n "$candidate" ]; then
      manifest="$candidate"
      found_via="${candidate#$dir/}"
    fi
  fi

  if [ -z "$manifest" ]; then
    record "M0" "SHOULD" "warn" "no sample install.manifest.json found in repo" \
      "checker did not validate manifest contents (repo has no fixture)"
    return
  fi

  # M1 — manifest is parseable JSON (MUST, §3.8)
  if command -v jq >/dev/null 2>&1; then
    if jq empty "$manifest" >/dev/null 2>&1; then
      record "M1" "MUST" "ok" "manifest at ${found_via} parses as JSON"
    else
      record "M1" "MUST" "fail" "manifest at ${found_via} is not valid JSON"
      return
    fi
  else
    record "M1" "MUST" "warn" "jq not available; cannot parse manifest" \
      "install jq for full manifest validation"
    return
  fi

  # Required fields (MUST, §3.1)
  _manifest_field "$manifest" "M2" "eidolon"     "MUST"
  _manifest_field "$manifest" "M3" "version"     "MUST"
  _manifest_field "$manifest" "M4" "methodology" "MUST"
  _manifest_field "$manifest" "M5" "installed_at" "MUST"
  _manifest_field "$manifest" "M6" "target"      "MUST"
  _manifest_field "$manifest" "M7" "hosts_wired" "MUST"
  _manifest_field "$manifest" "M8" "files_written" "MUST"

  # M9 — eidolon slug pattern (MUST, §3.1)
  local eidolon_val
  eidolon_val="$(jq -r '.eidolon // empty' "$manifest" 2>/dev/null)"
  if [ -n "$eidolon_val" ]; then
    if printf '%s' "$eidolon_val" | grep -Eq '^[a-z][a-z0-9-]*$'; then
      record "M9" "MUST" "ok" "eidolon slug '${eidolon_val}' matches ^[a-z][a-z0-9-]*$"
    else
      record "M9" "MUST" "fail" "eidolon slug '${eidolon_val}' violates pattern ^[a-z][a-z0-9-]*$"
    fi
  fi

  # M10 — version SemVer pattern (MUST, §3.1)
  local version_val
  version_val="$(jq -r '.version // empty' "$manifest" 2>/dev/null)"
  if [ -n "$version_val" ]; then
    if printf '%s' "$version_val" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      record "M10" "MUST" "ok" "version '${version_val}' matches SemVer ^\\d+\\.\\d+\\.\\d+$"
    else
      record "M10" "MUST" "fail" "version '${version_val}' violates SemVer pattern"
    fi
  fi

  # M11 — hosts_wired enum members (MUST, §3.2)
  local bad_hosts
  bad_hosts="$(jq -r '
    .hosts_wired // []
    | map(select(. as $h | ["claude-code","copilot","cursor","opencode","codex","raw"] | index($h) | not))
    | join(",")
  ' "$manifest" 2>/dev/null)"
  if [ -z "$bad_hosts" ]; then
    record "M11" "MUST" "ok" "hosts_wired entries are all in the EIIS enum"
  else
    record "M11" "MUST" "fail" "hosts_wired contains non-EIIS values: ${bad_hosts}"
  fi

  # M12 — files_written populated (MUST, warn-only in v1.0; D-3)
  local files_count
  files_count="$(jq -r '.files_written // [] | length' "$manifest" 2>/dev/null)"
  if [ "${files_count:-0}" -gt 0 ]; then
    record "M12" "MUST" "ok" "files_written populated (${files_count} entries)"
  else
    # D-3 grandfather window: warn-only in v1.0.
    record "M12" "MUST" "warn" "files_written-empty (D-3)" \
      "grandfathered until 2027-04-24"
  fi

  # M13 — files_written entries shape (MUST, §3.3)
  local bad_entries
  bad_entries="$(jq -r '
    [
      .files_written // []
      | .[]
      | select(
          (.path // "") == ""
          or (.sha256 // "") == ""
          or (.role // "") == ""
          or ((.role // "") as $r | ["entry-point","spec","skill","template","dispatch","manifest","agent-profile","persona","ecl-version","hook","other"] | index($r) | not)
        )
      | .path // "<missing>"
    ] | length
  ' "$manifest" 2>/dev/null)"
  if [ "${bad_entries:-0}" -eq 0 ]; then
    record "M13" "MUST" "ok" "files_written entries match {path, sha256, role}"
  else
    record "M13" "MUST" "fail" "files_written has ${bad_entries} malformed entries"
  fi

  # M14 — JSON Schema validation when a validator is on PATH (advisory)
  local schema="$(_locate_schema "$dir")"
  if [ -n "$schema" ]; then
    if command -v ajv >/dev/null 2>&1; then
      if ajv validate -s "$schema" -d "$manifest" >/dev/null 2>&1; then
        record "M14" "MUST" "ok" "manifest validates against ${schema} (via ajv)"
      else
        record "M14" "MUST" "fail" "manifest fails JSON Schema validation against ${schema}"
      fi
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' >/dev/null 2>&1; then
      if python3 -m jsonschema --instance "$manifest" "$schema" >/dev/null 2>&1; then
        record "M14" "MUST" "ok" "manifest validates against ${schema} (via python jsonschema)"
      else
        record "M14" "MUST" "fail" "manifest fails JSON Schema validation against ${schema}"
      fi
    else
      # No validator available; structural checks (M1-M13) covered the
      # required-field shape. Note this in the report without flagging
      # a warn (don't perturb exit code 0 for repos that pass everything
      # else).
      record "M14" "SHOULD" "ok" "JSON Schema validator not on PATH; relied on structural checks (install ajv or python jsonschema for full validation)"
    fi
  fi
}

_manifest_field() {
  # _manifest_field <manifest> <id> <field> <level>
  local manifest="$1" id="$2" field="$3" level="$4"
  local result
  result="$(jq -r "if has(\"$field\") then \"ok\" else \"fail\" end" "$manifest" 2>/dev/null)"
  if [ "$result" = "ok" ]; then
    record "$id" "$level" "ok" "manifest has field '${field}'"
  else
    record "$id" "$level" "fail" "manifest missing required field '${field}'"
  fi
}

_locate_schema() {
  # _locate_schema <repo-dir>
  # Look for a vendored copy first, then the EIIS repo's own copy
  # (relative to this script).
  local dir="$1"
  if [ -f "$dir/schemas/install.manifest.v1.json" ]; then
    echo "$dir/schemas/install.manifest.v1.json"
    return
  fi
  local self_schema
  self_schema="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/schemas/install.manifest.v1.json"
  if [ -f "$self_schema" ]; then
    echo "$self_schema"
    return
  fi
  echo ""
}
