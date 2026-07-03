# shellcheck shell=bash
# EIIS v1.4/v1.5 — canonical install-target inventory checks (§1.9, §1.8.6,
# §3.7.1, §3.7.2, §4.2.3-§4.2.5, §4.7, §6.Y). Sourced by check.sh.
#
# Checks added in v1.4:
#
#   I1  Inventory whitelist — every file under <target>/ is in the §1.9.1
#       whitelist. MUST-fail for EIIS_VERSION >= 1.4; warn-only for <= 1.3.
#       (v1.5: the whitelist gains a hooks/*.sh branch, active only when
#       EIIS_VERSION >= 1.5 — see I1's hooks handling below.)
#
#   I2  Two-file canonical pair — both agent.md (role agent-profile) and
#       SPEC.md (role spec) appear exactly once in files_written[].
#       MUST-fail for EIIS_VERSION >= 1.4; warn-only for <= 1.3.
#
#   I3  ECL_VERSION target copy — if source declares ECL_VERSION,
#       files_written[] must contain a role ecl-version entry.
#       MUST-fail for EIIS_VERSION >= 1.4; warn-only for <= 1.3.
#
#   I4  Host-vendor refs — .claude/agents/<slug>.md references both
#       agent.md and SPEC.md; references no legacy filenames.
#       MUST-fail for EIIS_VERSION >= 1.4; warn-only for <= 1.3.
#
#   I5  agent.md skill-path consistency — every skills/<skill>.md
#       reference inside <target>/agent.md resolves to a files_written[]
#       entry; no subdir paths; no legacy spec basenames.
#       MUST-fail for EIIS_VERSION >= 1.4; warn-only for <= 1.3.
#
# Check added in v1.5 (EIIS v1.5 §3.7.2, §1.9.7-§1.9.9):
#
#   I6  Hook role / hook_event consistency —
#       (a) every files_written[] entry with role "hook" carries a valid
#           hook_event (session-start|prompt-submit|pre-tool|stop);
#       (b) every file under <target>/hooks/ is manifest-declared with
#           role "hook" (sweep symmetry with §6.X.7).
#       MUST-fail for EIIS_VERSION >= 1.5; warn-only for <= 1.4.
#
# Bash 3.2 compatible. Hard dep: jq (already required by check.sh).
#
# Public function: eiis_check_inventory <repo-dir-absolute> <target-version>

eiis_check_inventory() {
  local dir="$1"
  local target_version="$2"

  # --------------------------------------------------------------------------- #
  # Determine whether v1.4+ MUST-fail gating applies.
  # --------------------------------------------------------------------------- #

  local is_v14_or_later=0
  case "$target_version" in
    1.0|1.0.*|1|1.1|1.1.*|1.2|1.2.*|1.3|1.3.*) is_v14_or_later=0 ;;
    1.4|1.4.*|1.5|1.5.*|1.6|1.6.*|1.7|1.7.*|1.8|1.8.*|1.9|1.9.*) is_v14_or_later=1 ;;
    1.*) is_v14_or_later=1 ;;
    *) is_v14_or_later=0 ;;
  esac

  # --------------------------------------------------------------------------- #
  # Determine whether v1.5+ MUST-fail gating applies (I6; hooks/ in I1's
  # whitelist). EIIS v1.5 §3.7.2.5, §1.9.9.
  # --------------------------------------------------------------------------- #

  local is_v15_or_later=0
  case "$target_version" in
    1.0|1.0.*|1|1.1|1.1.*|1.2|1.2.*|1.3|1.3.*|1.4|1.4.*) is_v15_or_later=0 ;;
    1.5|1.5.*|1.6|1.6.*|1.7|1.7.*|1.8|1.8.*|1.9|1.9.*) is_v15_or_later=1 ;;
    1.*) is_v15_or_later=1 ;;
    *) is_v15_or_later=0 ;;
  esac

  # --------------------------------------------------------------------------- #
  # Locate the manifest (same priority as checks-manifest.sh and
  # checks-spec-skills.sh: examples/ first, then first found by find).
  # --------------------------------------------------------------------------- #

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
    # No manifest — skip I-series (no fixture to check).
    record "I1" "MUST" "ok" \
      "I1:inventory — inventory checks skipped (no manifest found)"
    record "I2" "MUST" "ok" \
      "I2:two-file-pair — two-file-pair checks skipped (no manifest found)"
    record "I3" "MUST" "ok" \
      "I3:ecl-version — ECL_VERSION checks skipped (no manifest found)"
    record "I4" "MUST" "ok" \
      "I4:host-vendor — host-vendor checks skipped (no manifest found)"
    record "I5" "MUST" "ok" \
      "I5:agent-skill-refs — agent.md skill-ref checks skipped (no manifest found)"
    record "I6" "MUST" "ok" \
      "I6:hook-consistency — hook checks skipped (no manifest found)"
    return
  fi

  if ! jq empty "$manifest" >/dev/null 2>&1; then
    # Manifest is invalid JSON — skip (M1 failure already recorded elsewhere).
    record "I1" "MUST" "ok" \
      "I1:inventory — skipped (manifest is not valid JSON)"
    record "I2" "MUST" "ok" \
      "I2:two-file-pair — skipped (manifest is not valid JSON)"
    record "I3" "MUST" "ok" \
      "I3:ecl-version — skipped (manifest is not valid JSON)"
    record "I4" "MUST" "ok" \
      "I4:host-vendor — skipped (manifest is not valid JSON)"
    record "I5" "MUST" "ok" \
      "I5:agent-skill-refs — skipped (manifest is not valid JSON)"
    record "I6" "MUST" "ok" \
      "I6:hook-consistency — skipped (manifest is not valid JSON)"
    return
  fi

  # Derive the slug and install target from the manifest.
  local slug
  slug="$(jq -r '.eidolon // empty' "$manifest" 2>/dev/null)"
  local target_field
  target_field="$(jq -r '.target // empty' "$manifest" 2>/dev/null)"

  # The target field is consumer-relative (e.g. "./.eidolons/apivr").
  # When checking a fixture we do not have an actual install on disk — the
  # inventory check (I1) uses an optional sibling "target_dir" fixture dir.
  # The manifest / agent.md content checks (I2-I5) work from the manifest
  # JSON alone so they do not need the on-disk target.

  # For I1 we need the actual on-disk target directory. Fixtures supply it as
  # a "target/" subdirectory adjacent to the manifest, or as a path derived
  # from the manifest's `target` field relative to the fixture root.
  # Strategy: look for `<fixture-root>/target/` first; otherwise skip I1.
  local fixture_root
  fixture_root="$(dirname "$manifest")"
  # If the manifest is inside examples/, step up one level.
  case "$fixture_root" in
    */examples) fixture_root="$(dirname "$fixture_root")" ;;
  esac

  # ----------------------------------------------------------------- #
  # I1 — Inventory whitelist
  # ----------------------------------------------------------------- #
  # The §1.9.1 whitelist. We check by parent-directory and basename.
  #
  # Allowed patterns (target-relative):
  #   agent.md
  #   SPEC.md
  #   install.manifest.json
  #   ECL_VERSION
  #   skills/<flat>.md           (one level under skills/, no sub-dirs)
  #   templates/<flat>.md        (one level under templates/, no sub-dirs)
  #   schemas/<anything>.json    (under schemas/)
  #
  # Anything else is non-whitelisted.

  local target_on_disk=""
  if [ -d "${fixture_root}/target" ]; then
    target_on_disk="${fixture_root}/target"
  fi

  if [ -z "$target_on_disk" ]; then
    # Cannot perform disk-based I1 check without an on-disk target.
    record "I1" "MUST" "ok" \
      "I1:inventory — no on-disk target dir found (fixture must supply target/); check skipped"
  else
    local i1_bad=""
    # Find all files under target_on_disk, then classify each.
    while IFS= read -r -d '' file; do
      local rel="${file#${target_on_disk}/}"
      local whitelisted=0

      # Split on first '/' to get parent and tail.
      local parent="${rel%%/*}"
      local tail="${rel#*/}"

      case "$rel" in
        agent.md|SPEC.md|install.manifest.json|ECL_VERSION)
          # Root-level whitelisted files.
          whitelisted=1
          ;;
        skills/*)
          # Only flat: skills/<name>.md — no further slashes.
          case "$tail" in
            */*) whitelisted=0 ;;  # sub-dir (e.g. skills/phase/SKILL.md)
            *.md) whitelisted=1 ;;
            *) whitelisted=0 ;;
          esac
          ;;
        templates/*)
          case "$tail" in
            */*) whitelisted=0 ;;
            *.md) whitelisted=1 ;;
            *) whitelisted=0 ;;
          esac
          ;;
        schemas/*)
          case "$tail" in
            */*) whitelisted=0 ;;
            *.json) whitelisted=1 ;;
            *) whitelisted=0 ;;
          esac
          ;;
        hooks/*)
          # hooks/ only entered the whitelist at v1.5 (EIIS v1.5 §1.9.7).
          # A v1.4-declared Eidolon shipping a hooks/ dir still fails I1 —
          # the path was not enumerated before v1.5.
          if [ "$is_v15_or_later" -eq 1 ]; then
            case "$tail" in
              */*) whitelisted=0 ;;  # no subdirs under hooks/ (§1.9.8)
              *.sh) whitelisted=1 ;;
              *) whitelisted=0 ;;
            esac
          else
            whitelisted=0
          fi
          ;;
        *)
          whitelisted=0
          ;;
      esac

      if [ "$whitelisted" -eq 0 ]; then
        if [ -z "$i1_bad" ]; then
          i1_bad="$rel"
        else
          i1_bad="${i1_bad}, ${rel}"
        fi
      fi
    done < <(find "$target_on_disk" -type f -print0 2>/dev/null)

    if [ -z "$i1_bad" ]; then
      record "I1" "MUST" "ok" \
        "I1:inventory — all files in target/ are in the §1.9.1 whitelist (EIIS v1.4)"
    else
      if [ "$is_v14_or_later" -eq 1 ]; then
        record "I1" "MUST" "fail" \
          "I1:inventory — non-whitelisted file(s) found in target/: ${i1_bad} (EIIS v1.4 §1.9.1)"
      else
        record "I1" "MUST" "warn" \
          "I1:inventory — non-whitelisted file(s) in target/: ${i1_bad}" \
          "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.4+"
      fi
    fi
  fi

  # ----------------------------------------------------------------- #
  # I2 — Two-file canonical pair: agent-profile + spec
  # ----------------------------------------------------------------- #

  # Count agent-profile entries.
  local ap_count
  ap_count="$(jq -r '[ .files_written // [] | .[] | select(.role == "agent-profile") ] | length' "$manifest" 2>/dev/null)"
  # Check basename of agent-profile entry.
  local ap_path
  ap_path="$(jq -r '[ .files_written // [] | .[] | select(.role == "agent-profile") ] | .[0].path // ""' "$manifest" 2>/dev/null)"
  local ap_basename="${ap_path##*/}"

  # Count spec entries (reuse S1-style logic).
  local sp_count
  sp_count="$(jq -r '[ .files_written // [] | .[] | select(.role == "spec") ] | length' "$manifest" 2>/dev/null)"
  local sp_path
  sp_path="$(jq -r '[ .files_written // [] | .[] | select(.role == "spec") ] | .[0].path // ""' "$manifest" 2>/dev/null)"
  local sp_basename="${sp_path##*/}"

  local i2_fail=""

  # agent-profile checks.
  if [ "${ap_count:-0}" -eq 0 ]; then
    i2_fail="${i2_fail}no 'agent-profile' role entry; "
  elif [ "${ap_count:-0}" -gt 1 ]; then
    i2_fail="${i2_fail}${ap_count} 'agent-profile' entries (exactly one required); "
  elif [ "$ap_basename" != "agent.md" ]; then
    i2_fail="${i2_fail}agent-profile path='${ap_path}' basename='${ap_basename}' is not agent.md; "
  fi

  # spec checks (complementary to S1 — I2 focuses on co-presence).
  if [ "${sp_count:-0}" -eq 0 ]; then
    i2_fail="${i2_fail}no 'spec' role entry; "
  elif [ "${sp_count:-0}" -gt 1 ]; then
    i2_fail="${i2_fail}${sp_count} 'spec' entries (exactly one required); "
  elif [ "$sp_basename" != "SPEC.md" ]; then
    i2_fail="${i2_fail}spec path='${sp_path}' basename='${sp_basename}' is not SPEC.md; "
  fi

  if [ -z "$i2_fail" ]; then
    record "I2" "MUST" "ok" \
      "I2:two-file-pair — exactly one agent-profile (agent.md) and one spec (SPEC.md) in files_written[] (EIIS v1.4 §1.8.6)"
  else
    if [ "$is_v14_or_later" -eq 1 ]; then
      record "I2" "MUST" "fail" \
        "I2:two-file-pair — ${i2_fail}(EIIS v1.4 §1.8.6)"
    else
      record "I2" "MUST" "ok" \
        "I2:two-file-pair — ${i2_fail}(not required at EIIS_VERSION ${target_version}; MUST-fail at v1.4+)"
    fi
  fi

  # ----------------------------------------------------------------- #
  # I3 — ECL_VERSION install-target copy
  # ----------------------------------------------------------------- #
  # Check: if source declares ECL_VERSION (file exists at fixture root),
  # OR if <target>/ECL_VERSION exists on disk, then files_written[] must
  # contain a role:"ecl-version" entry pointing at ECL_VERSION.
  # When only checking via manifest (no on-disk target), we look for
  # the source ECL_VERSION at the fixture root.

  local source_ecl_declared=0
  if [ -f "${fixture_root}/ECL_VERSION" ]; then
    source_ecl_declared=1
  fi

  # Also check if files_written contains ecl-version (which implies source
  # declared it — the installer should only write it when source has it).
  local ecl_count
  ecl_count="$(jq -r '[ .files_written // [] | .[] | select(.role == "ecl-version") ] | length' "$manifest" 2>/dev/null)"

  # Check the on-disk ECL_VERSION in target if available.
  local target_ecl_exists=0
  if [ -n "$target_on_disk" ] && [ -f "${target_on_disk}/ECL_VERSION" ]; then
    target_ecl_exists=1
  fi

  # Logic:
  # - Source declares ECL_VERSION AND (ecl_count == 0) -> fail
  # - files_written has ecl-version entries but source doesn't declare ECL_VERSION
  #   -> suspicious but not a v1.4 MUST violation (source may have ECL_VERSION
  #   outside the fixture root detection path)
  # - target ECL_VERSION on disk but not in files_written -> fail

  local i3_fail=""
  if [ "$source_ecl_declared" -eq 1 ] && [ "${ecl_count:-0}" -eq 0 ]; then
    i3_fail="source declares ECL_VERSION but no 'ecl-version' role entry in files_written[]"
  fi
  if [ "$target_ecl_exists" -eq 1 ] && [ "${ecl_count:-0}" -eq 0 ]; then
    i3_fail="${i3_fail}; target/ECL_VERSION on disk but not in files_written[]"
  fi
  # Check that ecl-version path has ECL_VERSION basename.
  if [ "${ecl_count:-0}" -gt 0 ]; then
    local ecl_path
    ecl_path="$(jq -r '[ .files_written // [] | .[] | select(.role == "ecl-version") ] | .[0].path // ""' "$manifest" 2>/dev/null)"
    local ecl_basename="${ecl_path##*/}"
    if [ "$ecl_basename" != "ECL_VERSION" ]; then
      i3_fail="${i3_fail}; ecl-version entry path='${ecl_path}' basename='${ecl_basename}' is not ECL_VERSION"
    fi
  fi

  if [ -z "$i3_fail" ]; then
    record "I3" "MUST" "ok" \
      "I3:ecl-version — ECL_VERSION install-target copy correctly tracked in files_written[] (EIIS v1.4 §3.7.1)"
  else
    if [ "$is_v14_or_later" -eq 1 ]; then
      record "I3" "MUST" "fail" \
        "I3:ecl-version — ${i3_fail} (EIIS v1.4 §3.7.1)"
    else
      record "I3" "MUST" "ok" \
        "I3:ecl-version — ${i3_fail} (not required at EIIS_VERSION ${target_version}; MUST-fail at v1.4+)"
    fi
  fi

  # ----------------------------------------------------------------- #
  # I4 — Host-vendor refs: .claude/agents/<slug>.md body contract
  # ----------------------------------------------------------------- #
  # Check the fixture's .claude/agents/<slug>.md file if present.
  # We look relative to the fixture root.

  if [ -z "$slug" ]; then
    record "I4" "MUST" "ok" \
      "I4:host-vendor — skipped (could not determine eidolon slug from manifest)"
  else
    local claude_agent_file="${fixture_root}/.claude/agents/${slug}.md"

    if [ ! -f "$claude_agent_file" ]; then
      # Not present — check skipped (no claude-code host wired or file missing).
      local hosts_has_claude
      hosts_has_claude="$(jq -r '
        if (.hosts_wired // [] | map(select(. == "claude-code")) | length) > 0
        then "yes" else "no" end
      ' "$manifest" 2>/dev/null)"

      if [ "$hosts_has_claude" = "yes" ]; then
        if [ "$is_v14_or_later" -eq 1 ]; then
          record "I4" "MUST" "fail" \
            "I4:host-vendor — claude-code in hosts_wired but .claude/agents/${slug}.md not found at fixture root (EIIS v1.4 §4.2.3)"
        else
          record "I4" "MUST" "ok" \
            "I4:host-vendor — claude-code in hosts_wired but .claude/agents/${slug}.md not found (not required at EIIS_VERSION ${target_version}; MUST-fail at v1.4+)"
        fi
      else
        record "I4" "MUST" "ok" \
          "I4:host-vendor — claude-code not in hosts_wired; body-contract check skipped"
      fi
    else
      local i4_fail=""

      # §4.2.3: MUST reference both agent.md and SPEC.md (literal strings).
      local agent_ref="./.eidolons/${slug}/agent.md"
      local spec_ref="./.eidolons/${slug}/SPEC.md"

      if ! grep -qF "$agent_ref" "$claude_agent_file" 2>/dev/null; then
        i4_fail="${i4_fail}missing reference to '${agent_ref}'; "
      fi
      if ! grep -qF "$spec_ref" "$claude_agent_file" 2>/dev/null; then
        i4_fail="${i4_fail}missing reference to '${spec_ref}'; "
      fi

      # §4.2.4: MUST NOT reference legacy spec filenames (slug.md case-insensitive)
      # or AGENTS.md as an install-target path.
      # Pattern: .eidolons/<slug>/<slug>.md (case-insensitive on the basename).
      if grep -qiE "\.eidolons/${slug}/${slug}\.md" "$claude_agent_file" 2>/dev/null; then
        i4_fail="${i4_fail}references legacy spec filename (.eidolons/${slug}/${slug}.md); "
      fi
      # REASONER.md / SCRIBE.md legacy names.
      if grep -qiE "\.eidolons/${slug}/(REASONER|SCRIBE|AGENTS)\.md" "$claude_agent_file" 2>/dev/null; then
        i4_fail="${i4_fail}references a legacy file (REASONER.md, SCRIBE.md, or AGENTS.md) in install target; "
      fi

      # §4.2.5: MUST NOT reference skills/<phase>/SKILL.md subdir paths.
      if grep -qE "skills/[a-z0-9-]+/SKILL\.md" "$claude_agent_file" 2>/dev/null; then
        i4_fail="${i4_fail}references skills/<phase>/SKILL.md subdir layout (deprecated by v1.3 §4.2.4.3); "
      fi

      if [ -z "$i4_fail" ]; then
        record "I4" "MUST" "ok" \
          "I4:host-vendor — .claude/agents/${slug}.md correctly references agent.md + SPEC.md, no legacy names (EIIS v1.4 §4.2.3-§4.2.5)"
      else
        if [ "$is_v14_or_later" -eq 1 ]; then
          record "I4" "MUST" "fail" \
            "I4:host-vendor — .claude/agents/${slug}.md: ${i4_fail}(EIIS v1.4 §4.2.3-§4.2.5)"
        else
          record "I4" "MUST" "ok" \
            "I4:host-vendor — .claude/agents/${slug}.md: ${i4_fail}(not required at EIIS_VERSION ${target_version}; MUST-fail at v1.4+)"
        fi
      fi
    fi
  fi

  # ----------------------------------------------------------------- #
  # I6 — hook role / hook_event consistency (EIIS v1.5 §3.7.2, §1.9.7-9)
  # ----------------------------------------------------------------- #
  # Placed before I5 (not after) because I5 `return`s early when no
  # agent.md is found at the fixture — I6 must run regardless of that.
  #
  # (a) every files_written[] entry with role "hook" MUST carry a valid
  #     hook_event (session-start|prompt-submit|pre-tool|stop).
  # (b) every file under <target>/hooks/ MUST be manifest-declared with
  #     role "hook" (sweep symmetry with §6.X.7).

  local i6_fail=""

  local hook_entries
  hook_entries="$(jq -c '.files_written // [] | .[] | select(.role == "hook")' "$manifest" 2>/dev/null)"

  if [ -n "$hook_entries" ]; then
    local h_entry h_path h_event
    while IFS= read -r h_entry; do
      [ -z "$h_entry" ] && continue
      h_path="$(printf '%s' "$h_entry" | jq -r '.path // ""' 2>/dev/null)"
      h_event="$(printf '%s' "$h_entry" | jq -r '.hook_event // ""' 2>/dev/null)"
      case "$h_event" in
        session-start|prompt-submit|pre-tool|stop) : ;;
        "")
          i6_fail="${i6_fail}files_written entry '${h_path}' has role 'hook' but is missing hook_event; "
          ;;
        *)
          i6_fail="${i6_fail}files_written entry '${h_path}' has role 'hook' with invalid hook_event='${h_event}'; "
          ;;
      esac
    done <<EOF_HOOK_ENTRIES
$hook_entries
EOF_HOOK_ENTRIES
  fi

  # (b) sweep symmetry: every file under <target>/hooks/ is manifest-declared
  # with role "hook". Requires the on-disk target (same target_on_disk used
  # by I1 above).
  if [ -n "$target_on_disk" ] && [ -d "${target_on_disk}/hooks" ]; then
    local fw_hook_paths
    fw_hook_paths="$(jq -r '.files_written // [] | .[] | select(.role == "hook") | .path' "$manifest" 2>/dev/null)"

    while IFS= read -r -d '' hfile; do
      local hrel="${hfile#${target_on_disk}/}"
      local hfound=0
      local hfw_path
      while IFS= read -r hfw_path; do
        [ -z "$hfw_path" ] && continue
        case "$hfw_path" in
          *"/${hrel}"|"${hrel}")
            hfound=1
            break
            ;;
        esac
      done <<EOF_FW_HOOKS
$fw_hook_paths
EOF_FW_HOOKS
      if [ "$hfound" -eq 0 ]; then
        i6_fail="${i6_fail}file '${hrel}' under <target>/hooks/ is not declared in files_written[] with role 'hook'; "
      fi
    done < <(find "${target_on_disk}/hooks" -type f -print0 2>/dev/null)
  fi

  if [ -z "$i6_fail" ]; then
    record "I6" "MUST" "ok" \
      "I6:hook-consistency — role-hook entries have valid hook_event and hooks/ sweep symmetry holds (EIIS v1.5 §3.7.2, §1.9.7)"
  else
    if [ "$is_v15_or_later" -eq 1 ]; then
      record "I6" "MUST" "fail" \
        "I6:hook-consistency — ${i6_fail}(EIIS v1.5 §3.7.2, §1.9.7)"
    else
      record "I6" "MUST" "warn" \
        "I6:hook-consistency — ${i6_fail}" \
        "warn-only for EIIS_VERSION ${target_version}; MUST-fail at v1.5+"
    fi
  fi

  # ----------------------------------------------------------------- #
  # I5 — agent.md skill-path consistency
  # ----------------------------------------------------------------- #
  # Check <target>/agent.md (via on-disk target or fixture source agent.md).

  local agent_md_path=""
  if [ -n "$target_on_disk" ] && [ -f "${target_on_disk}/agent.md" ]; then
    agent_md_path="${target_on_disk}/agent.md"
  elif [ -f "${fixture_root}/agent.md" ]; then
    agent_md_path="${fixture_root}/agent.md"
  fi

  if [ -z "$agent_md_path" ]; then
    record "I5" "MUST" "ok" \
      "I5:agent-skill-refs — no agent.md found at fixture; check skipped"
    return
  fi

  local i5_fail=""

  # §6.Y.2: MUST NOT reference skills/<phase>/SKILL.md subdir paths.
  if grep -qE "skills/[a-z0-9-]+/SKILL\.md" "$agent_md_path" 2>/dev/null; then
    i5_fail="${i5_fail}agent.md references skills/<phase>/SKILL.md subdir layout (EIIS v1.4 §6.Y.2); "
  fi

  # §6.Y.3: MUST NOT reference legacy spec basename (<slug>.md) case-insensitively.
  if [ -n "$slug" ]; then
    if grep -qiE "(^|[^a-zA-Z0-9-])${slug}\.md([^a-zA-Z0-9-]|$)" "$agent_md_path" 2>/dev/null; then
      i5_fail="${i5_fail}agent.md references legacy spec filename (${slug}.md) (EIIS v1.4 §6.Y.3); "
    fi
  fi

  # §6.Y.1: every skills/<skill>.md reference must resolve to a files_written[] entry.
  # Extract flat skill references (skills/<name>.md — no slash in name part).
  local skill_refs
  skill_refs="$(grep -oE 'skills/[a-z0-9-]+\.md' "$agent_md_path" 2>/dev/null | sort -u)"

  if [ -n "$skill_refs" ]; then
    # Build a list of skill paths from files_written[].
    local fw_skills
    fw_skills="$(jq -r '.files_written // [] | .[] | select(.role == "skill") | .path' "$manifest" 2>/dev/null)"

    local ref
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      local skill_name="${ref#skills/}"
      # Check if any files_written path ends with skills/<skill_name>.
      local found=0
      local fw_path
      while IFS= read -r fw_path; do
        case "$fw_path" in
          */skills/"$skill_name"|skills/"$skill_name")
            found=1
            break
            ;;
        esac
      done <<EOF_FW
$fw_skills
EOF_FW
      if [ "$found" -eq 0 ]; then
        i5_fail="${i5_fail}agent.md references '${ref}' but no matching skill in files_written[] (EIIS v1.4 §6.Y.1); "
      fi
    done <<EOF_REFS
$skill_refs
EOF_REFS
  fi

  if [ -z "$i5_fail" ]; then
    record "I5" "MUST" "ok" \
      "I5:agent-skill-refs — agent.md skill references are consistent with files_written[] (EIIS v1.4 §6.Y)"
  else
    if [ "$is_v14_or_later" -eq 1 ]; then
      record "I5" "MUST" "fail" \
        "I5:agent-skill-refs — ${i5_fail}"
    else
      record "I5" "MUST" "ok" \
        "I5:agent-skill-refs — ${i5_fail}(not required at EIIS_VERSION ${target_version}; MUST-fail at v1.4+)"
    fi
  fi
}
