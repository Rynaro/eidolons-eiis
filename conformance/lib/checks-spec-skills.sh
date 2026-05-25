# shellcheck shell=bash
# EIIS v1.3 — canonical SPEC.md (§1.8) and skills dual-write (§4.2.4) checks.
# Sourced by check.sh.
#
# Checks added in v1.3:
#
#   S1  The single files_written[] entry with role "spec" has basename SPEC.md.
#       MUST-fail for EIIS_VERSION >= 1.3; warn-only for <= 1.2.
#
#   S2  spec_file field is present in the manifest and matches the role "spec"
#       entry's path. MUST-fail for EIIS_VERSION >= 1.3.
#
#   K1  If skills[] is present, each source_path matches the flat layout
#       pattern. MUST-fail for EIIS_VERSION >= 1.3; warn-only for <= 1.2.
#
#   K2  If vendor_sha256 is present in a skills[] entry, it equals
#       source_sha256. MUST-fail for EIIS_VERSION >= 1.3; warn-only for <= 1.2.
#
#   K3  If claude-code is in hosts_wired and any skills[] entry exists,
#       vendor_path is present. WARN only (any version).
#
# Bash 3.2 compatible. Hard dep: jq (already required by check.sh).
#
# Public function: eiis_check_spec_skills <repo-dir-absolute> <target-version>

eiis_check_spec_skills() {
  local dir="$1"
  local target_version="$2"

  # Locate the manifest — same priority logic as checks-manifest.sh.
  local manifest=""
  if [ -f "$dir/examples/install.manifest.json" ]; then
    manifest="$dir/examples/install.manifest.json"
  else
    local candidate
    candidate="$(find "$dir" -maxdepth 4 -name install.manifest.json -type f 2>/dev/null | head -n 1)"
    if [ -n "$candidate" ]; then
      manifest="$candidate"
    fi
  fi

  if [ -z "$manifest" ]; then
    # No manifest to check; M0 advisory already recorded by checks-manifest.sh.
    record "S1" "MUST" "ok" \
      "spec_file/skills checks skipped — no manifest found (no fixture)"
    return
  fi

  if ! jq empty "$manifest" >/dev/null 2>&1; then
    # Manifest is not valid JSON; M1 failure already recorded.
    record "S1" "MUST" "ok" \
      "spec_file/skills checks skipped — manifest is not valid JSON"
    return
  fi

  # Determine whether new MUSTs apply:
  # EIIS_VERSION >= 1.3 means MUST-fail; < 1.3 means warn-only.
  # We compare the major.minor prefix.
  local is_v13_or_later=0
  case "$target_version" in
    1.0|1.0.*|1|1.1|1.1.*|1.2|1.2.*) is_v13_or_later=0 ;;
    1.3|1.3.*|1.4|1.4.*|1.5|1.5.*|1.6|1.6.*|1.7|1.7.*|1.8|1.8.*|1.9|1.9.*)
      is_v13_or_later=1 ;;
    1.*)
      # Future 1.x beyond 1.3 — treat as v1.3+ for new checks.
      is_v13_or_later=1 ;;
    *)
      is_v13_or_later=0 ;;
  esac

  # ----------------------------------------------------------------- #
  # S1 — role "spec" entry has basename SPEC.md
  # ----------------------------------------------------------------- #

  # Count files_written[] entries with role "spec".
  local spec_count
  spec_count="$(jq -r '[ .files_written // [] | .[] | select(.role == "spec") ] | length' "$manifest" 2>/dev/null)"

  if [ "${spec_count:-0}" -eq 0 ]; then
    # No spec entry at all.
    # - v1.0/v1.1/v1.2: EIIS did not require a spec entry; record ok (no noise).
    # - v1.3+: MUST have exactly one spec entry (§1.8.3); fail.
    if [ "$is_v13_or_later" -eq 1 ]; then
      record "S1" "MUST" "fail" \
        "S1:spec-missing — no files_written entry with role 'spec' (EIIS v1.3 §1.8.3)"
    else
      record "S1" "MUST" "ok" \
        "S1:spec-missing — no role 'spec' entry; OK for EIIS_VERSION ${target_version} (required at v1.3+)"
    fi
  elif [ "${spec_count:-0}" -gt 1 ]; then
    if [ "$is_v13_or_later" -eq 1 ]; then
      record "S1" "MUST" "fail" \
        "S1:spec-ambiguous — ${spec_count} files_written entries with role 'spec'; exactly one required (EIIS v1.3 §1.8.3)"
    else
      record "S1" "MUST" "warn" \
        "S1:spec-ambiguous — ${spec_count} files_written entries with role 'spec'" \
        "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.3+"
    fi
  else
    # Exactly one spec entry — check its basename.
    local spec_path
    spec_path="$(jq -r '[ .files_written // [] | .[] | select(.role == "spec") ] | .[0].path' "$manifest" 2>/dev/null)"
    local spec_basename
    # Strip everything up to and including the last '/'.
    spec_basename="${spec_path##*/}"

    if [ "$spec_basename" = "SPEC.md" ]; then
      record "S1" "MUST" "ok" \
        "S1:spec-basename — role 'spec' entry path='${spec_path}' has basename SPEC.md (EIIS v1.3 §1.8.2)"
    else
      if [ "$is_v13_or_later" -eq 1 ]; then
        record "S1" "MUST" "fail" \
          "S1:spec-basename — role 'spec' entry path='${spec_path}' basename='${spec_basename}' is not SPEC.md (EIIS v1.3 §1.8.2)"
      else
        record "S1" "MUST" "warn" \
          "S1:spec-basename — role 'spec' entry basename='${spec_basename}' should be SPEC.md" \
          "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.3+"
      fi
    fi
  fi

  # ----------------------------------------------------------------- #
  # S2 — spec_file field present and matches the role "spec" path
  # ----------------------------------------------------------------- #

  if [ "$is_v13_or_later" -eq 1 ]; then
    local spec_file_val
    spec_file_val="$(jq -r '.spec_file // empty' "$manifest" 2>/dev/null)"

    if [ -z "$spec_file_val" ]; then
      record "S2" "MUST" "fail" \
        "S2:spec-file-missing — manifest lacks 'spec_file' field (EIIS v1.3 §1.8; required at EIIS_VERSION >= 1.3)"
    else
      # Validate the pattern: ^\.eidolons/[a-z][a-z0-9-]*/SPEC\.md$
      if printf '%s' "$spec_file_val" | grep -Eq '^\.(eidolons)/[a-z][a-z0-9-]*/SPEC\.md$'; then
        record "S2" "MUST" "ok" \
          "S2:spec-file — spec_file='${spec_file_val}' present and pattern-valid (EIIS v1.3 §1.8)"
      else
        record "S2" "MUST" "fail" \
          "S2:spec-file-pattern — spec_file='${spec_file_val}' does not match ^.eidolons/[a-z][a-z0-9-]*/SPEC.md$ (EIIS v1.3 §1.8.2)"
      fi
    fi
  else
    # For pre-v1.3 targets, spec_file is optional; record informational ok.
    local spec_file_val
    spec_file_val="$(jq -r '.spec_file // empty' "$manifest" 2>/dev/null)"
    if [ -n "$spec_file_val" ]; then
      record "S2" "MUST" "ok" \
        "S2:spec-file — spec_file='${spec_file_val}' present (optional at EIIS_VERSION ${target_version})"
    else
      record "S2" "MUST" "ok" \
        "S2:spec-file — spec_file not present (optional at EIIS_VERSION ${target_version}; required at v1.3+)"
    fi
  fi

  # ----------------------------------------------------------------- #
  # K-series — skills dual-write checks
  # ----------------------------------------------------------------- #

  local skills_count
  skills_count="$(jq -r '(.skills // []) | length' "$manifest" 2>/dev/null)"

  if [ "${skills_count:-0}" -eq 0 ]; then
    # No skills declared — K checks are vacuously OK.
    record "K1" "MUST" "ok" \
      "K1:skills-flat — no skills[] entries in manifest (checks vacuously pass)"
    record "K2" "MUST" "ok" \
      "K2:skills-sha — no skills[] entries in manifest (checks vacuously pass)"
    record "K3" "WARN" "ok" \
      "K3:skills-vendor — no skills[] entries in manifest (check vacuously passes)"
    return
  fi

  # K1 — each source_path matches flat layout pattern
  local k1_bad_count
  k1_bad_count="$(jq -r '
    [ .skills // []
      | .[]
      | select(
          (.source_path // "") | test("^\\.eidolons/[a-z][a-z0-9-]*/skills/[a-z][a-z0-9-]*\\.md$") | not
        )
      | .name // "<unnamed>"
    ] | length
  ' "$manifest" 2>/dev/null)"

  if [ "${k1_bad_count:-0}" -eq 0 ]; then
    record "K1" "MUST" "ok" \
      "K1:skills-flat — all ${skills_count} skill(s) have flat source_path layout (EIIS v1.3 §4.2.4.3)"
  else
    local k1_bad_names
    k1_bad_names="$(jq -r '
      [ .skills // []
        | .[]
        | select(
            (.source_path // "") | test("^\\.eidolons/[a-z][a-z0-9-]*/skills/[a-z][a-z0-9-]*\\.md$") | not
          )
        | .name // "<unnamed>"
      ] | join(", ")
    ' "$manifest" 2>/dev/null)"
    if [ "$is_v13_or_later" -eq 1 ]; then
      record "K1" "MUST" "fail" \
        "K1:skills-flat — ${k1_bad_count} skill(s) have non-flat source_path: ${k1_bad_names} (EIIS v1.3 §4.2.4.3)"
    else
      record "K1" "MUST" "warn" \
        "K1:skills-flat — ${k1_bad_count} skill(s) have non-flat source_path: ${k1_bad_names}" \
        "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.3+"
    fi
  fi

  # K2 — vendor_sha256, when present, equals source_sha256
  local k2_bad_count
  k2_bad_count="$(jq -r '
    [ .skills // []
      | .[]
      | select(
          (.vendor_sha256 // "") != ""
          and .vendor_sha256 != .source_sha256
        )
      | .name // "<unnamed>"
    ] | length
  ' "$manifest" 2>/dev/null)"

  if [ "${k2_bad_count:-0}" -eq 0 ]; then
    record "K2" "MUST" "ok" \
      "K2:skills-sha — all vendor_sha256 values match source_sha256 (EIIS v1.3 §4.2.4.2)"
  else
    local k2_bad_names
    k2_bad_names="$(jq -r '
      [ .skills // []
        | .[]
        | select(
            (.vendor_sha256 // "") != ""
            and .vendor_sha256 != .source_sha256
          )
        | .name // "<unnamed>"
      ] | join(", ")
    ' "$manifest" 2>/dev/null)"
    if [ "$is_v13_or_later" -eq 1 ]; then
      record "K2" "MUST" "fail" \
        "K2:skills-sha — ${k2_bad_count} skill(s) have vendor_sha256 != source_sha256: ${k2_bad_names} (EIIS v1.3 §4.2.4.2)"
    else
      record "K2" "MUST" "warn" \
        "K2:skills-sha — ${k2_bad_count} skill(s) have vendor_sha256 != source_sha256: ${k2_bad_names}" \
        "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.3+"
    fi
  fi

  # K3 — if claude-code in hosts_wired and skills exist, vendor_path present
  local has_claude_code
  has_claude_code="$(jq -r '
    if (.hosts_wired // [] | map(select(. == "claude-code")) | length) > 0
    then "yes" else "no" end
  ' "$manifest" 2>/dev/null)"

  if [ "$has_claude_code" = "yes" ]; then
    local k3_missing_count
    k3_missing_count="$(jq -r '
      [ .skills // []
        | .[]
        | select((.vendor_path // "") == "")
        | .name // "<unnamed>"
      ] | length
    ' "$manifest" 2>/dev/null)"

    if [ "${k3_missing_count:-0}" -eq 0 ]; then
      record "K3" "WARN" "ok" \
        "K3:skills-vendor — all ${skills_count} skill(s) have vendor_path (claude-code is wired, EIIS v1.3 §4.2.4.4)"
    else
      local k3_missing_names
      k3_missing_names="$(jq -r '
        [ .skills // []
          | .[]
          | select((.vendor_path // "") == "")
          | .name // "<unnamed>"
        ] | join(", ")
      ' "$manifest" 2>/dev/null)"
      record "K3" "WARN" "warn" \
        "K3:skills-vendor — ${k3_missing_count} skill(s) missing vendor_path with claude-code wired: ${k3_missing_names}" \
        "expected .claude/skills/<eidolon>-<skill>/SKILL.md entries (EIIS v1.3 §4.2.4.4)"
    fi
  else
    record "K3" "WARN" "ok" \
      "K3:skills-vendor — claude-code not in hosts_wired; vendor_path is optional (EIIS v1.3 §4.2.4.4)"
  fi
}
