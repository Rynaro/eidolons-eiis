# shellcheck shell=bash
# EIIS v3.0 — self-contained canonical-tree conformance gates.

eiis_v3_manifest() {
  local dir="$1"
  if [ -f "$dir/examples/install.manifest.json" ]; then
    printf '%s\n' "$dir/examples/install.manifest.json"
  else
    find "$dir" -maxdepth 4 -name install.manifest.json -type f 2>/dev/null | head -n 1
  fi
}

eiis_check_v3() {
  local dir="$1" target_version="$2" path manifest slug target persona spec bad count

  # V3-L1: the source repository itself uses the canonical vocabulary.
  bad=""
  for path in EIDOLONS.md PERSONA.md SPEC.md README.md install.sh EIIS_VERSION; do
    [ -f "$dir/$path" ] || bad="${bad}${path} missing; "
  done
  [ -f "$dir/agent.md" ] && bad="${bad}agent.md is forbidden at v3; "
  if [ -z "$bad" ]; then
    record "V3-L1" "MUST" "ok" "canonical source layout present"
  else
    record "V3-L1" "MUST" "fail" "canonical source layout" "$bad"
  fi

  # V3-L2: vendor-neutral root instructions are pointers, never copies.
  bad=""
  for path in AGENTS.md CLAUDE.md; do
    if [ -f "$dir/$path" ] && ! grep -q 'EIDOLONS\.md' "$dir/$path" 2>/dev/null; then
      bad="${bad}${path} does not refer to EIDOLONS.md; "
    fi
  done
  if [ -z "$bad" ]; then
    record "V3-L2" "MUST" "ok" "root host documents point to EIDOLONS.md"
  else
    record "V3-L2" "MUST" "fail" "root host documents are pointer-only" "$bad"
  fi

  # V3-S1: every source skill is a methodology directory with SKILL.md.
  bad=""
  if [ -d "$dir/skills" ]; then
    for path in "$dir"/skills/*; do
      [ -e "$path" ] || continue
      if [ ! -d "$path" ] || [ ! -f "$path/SKILL.md" ]; then
        bad="${bad}${path#"$dir/"} is not skills/<methodology>/SKILL.md; "
      fi
    done
  fi
  if [ -z "$bad" ]; then
    record "V3-S1" "MUST" "ok" "skills use directory entrypoints"
  else
    record "V3-S1" "MUST" "fail" "canonical skill layout" "$bad"
  fi

  manifest="$(eiis_v3_manifest "$dir")"
  if [ -z "$manifest" ] || ! jq empty "$manifest" >/dev/null 2>&1; then
    record "V3-M1" "MUST" "fail" "valid install.manifest.json fixture exists"
    return
  fi
  slug="$(jq -r '.eidolon // empty' "$manifest")"
  target="$(jq -r '.target // empty' "$manifest")"
  persona="$(jq -r '.persona_file // empty' "$manifest")"
  spec="$(jq -r '.spec_file // empty' "$manifest")"

  # V3-M1: manifest explicitly binds the major contract and canonical pair.
  bad=""
  case "$(jq -r '.eiis_version // empty' "$manifest")" in 3|3.*) ;; *) bad="${bad}eiis_version is not 3.x; ";; esac
  [ "$persona" = ".eidolons/${slug}/PERSONA.md" ] || bad="${bad}persona_file is not canonical; "
  [ "$spec" = ".eidolons/${slug}/SPEC.md" ] || bad="${bad}spec_file is not canonical; "
  count="$(jq '[.files_written[]? | select(.role == "persona")] | length' "$manifest")"
  [ "$count" -eq 1 ] || bad="${bad}exactly one persona role required; "
  count="$(jq '[.files_written[]? | select(.role == "spec")] | length' "$manifest")"
  [ "$count" -eq 1 ] || bad="${bad}exactly one spec role required; "
  if [ -z "$bad" ]; then
    record "V3-M1" "MUST" "ok" "manifest binds EIIS v3 and canonical persona/spec"
  else
    record "V3-M1" "MUST" "fail" "v3 manifest contract" "$bad"
  fi

  # Fixtures materialize the consumer target as target/.
  local installed="$dir/target"
  bad=""
  if [ -d "$installed" ]; then
    [ -f "$installed/PERSONA.md" ] || bad="${bad}target/PERSONA.md missing; "
    [ -f "$installed/SPEC.md" ] || bad="${bad}target/SPEC.md missing; "
    [ -f "$installed/agent.md" ] && bad="${bad}target/agent.md forbidden; "
    if [ -d "$installed/skills" ]; then
      for path in "$installed"/skills/*; do
        [ -e "$path" ] || continue
        if [ ! -d "$path" ] || [ ! -f "$path/SKILL.md" ]; then
          bad="${bad}${path#"$dir/"} is not a canonical skill directory; "
        fi
      done
    fi
  else
    # Source repositories need not commit an installed-tree fixture. Their CI
    # exercises install.sh; this static checker validates target/ when one is
    # deliberately materialized (all normative mutation fixtures do so).
    :
  fi
  if [ -z "$bad" ]; then
    if [ -d "$installed" ]; then
      record "V3-T1" "MUST" "ok" "installed tree is self-contained"
    else
      record "V3-T1" "MUST" "ok" "installed-tree fixture absent; installer validation delegated to CI"
    fi
  else
    record "V3-T1" "MUST" "fail" "self-contained installed tree" "$bad"
  fi

  # V3-A1: Claude skill discovery entries are symlinks into the canonical tree.
  bad=""
  if [ -d "$dir/.claude/skills" ]; then
    while IFS= read -r path; do
      [ -L "$path" ] || { bad="${bad}${path#"$dir/"} is a copied body; "; continue; }
      [ -e "$path" ] || { bad="${bad}${path#"$dir/"} is a broken symlink; "; continue; }
      case "$(readlink "$path" 2>/dev/null)" in
        *".eidolons/${slug}/skills/"*"/SKILL.md"|*"target/skills/"*"/SKILL.md") : ;;
        *) bad="${bad}${path#"$dir/"} does not resolve to canonical skill; " ;;
      esac
    done < <(find "$dir/.claude/skills" -name SKILL.md -print 2>/dev/null)
  fi
  if [ -z "$bad" ]; then
    record "V3-A1" "MUST" "ok" "vendor skill adapters are canonical symlinks"
  else
    record "V3-A1" "MUST" "fail" "vendor adapters must not duplicate skills" "$bad"
  fi

  # V3-H1: v1.5 hook semantics carry forward unchanged.
  bad=""
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    local hook_event
    hook_event="$(printf '%s' "$path" | jq -r '.hook_event // empty')"
    case "$hook_event" in
      session-start|prompt-submit|pre-tool|stop) : ;;
      *) bad="${bad}hook entry $(printf '%s' "$path" | jq -r '.path // "<unknown>"') has invalid hook_event; " ;;
    esac
  done <<EOF_V3_HOOKS
$(jq -c '.files_written[]? | select(.role == "hook")' "$manifest" 2>/dev/null)
EOF_V3_HOOKS
  if [ -d "$installed/hooks" ]; then
    while IFS= read -r path; do
      local hook_rel="${path#"$installed/"}"
      if ! jq -e --arg suffix "/$hook_rel" '[.files_written[]? | select(.role == "hook") | .path] | any(endswith($suffix))' "$manifest" >/dev/null 2>&1; then
        bad="${bad}${hook_rel} is not tracked with role hook; "
      fi
    done < <(find "$installed/hooks" -type f -print 2>/dev/null)
  fi
  if [ -z "$bad" ]; then
    record "V3-H1" "MUST" "ok" "hook events and inventory retain v1.5 guarantees"
  else
    record "V3-H1" "MUST" "fail" "v3 hook consistency" "$bad"
  fi
  # V3-I1: every regular installed file is tracked; adapters are tracked too.
  bad=""
  if [ -d "$installed" ]; then
    while IFS= read -r path; do
      local rel="${path#"$installed/"}"
      if ! jq -e --arg suffix "/$rel" '[.files_written[]?.path] | any(endswith($suffix))' "$manifest" >/dev/null 2>&1; then
        bad="${bad}${rel} is not manifest-tracked; "
      fi
    done < <(find "$installed" -type f ! -name install.manifest.json -print 2>/dev/null)
  fi
  if [ -z "$bad" ]; then
    record "V3-I1" "MUST" "ok" "canonical installed inventory is manifest-tracked"
  else
    record "V3-I1" "MUST" "fail" "manifest inventory completeness" "$bad"
  fi

  # Keep target_version observable in shellcheck-clean code and output intent.
  : "$target_version" "$target"
}
