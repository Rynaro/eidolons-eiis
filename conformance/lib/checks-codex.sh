# shellcheck shell=bash
# EIIS §4.5 — Codex subagent contract (v1.1+). Sourced by check.sh.
#
# Codex support is OPTIONAL. An Eidolon MAY ship a `.codex/agents/<name>.md`
# subagent file. If it does, the file MUST satisfy:
#   §4.5.2.1  YAML frontmatter delimited by `---` lines
#   §4.5.2.2  Required fields: `name` (slug), `description` (non-empty)
#   §4.5.2.3  Optional fields: `tools` (array), `model` (string)
#   §4.5.6    Distinct `name:` per file when multiple are present
#
# Exit-code semantics (consistent with check.sh aggregator):
#   - missing `.codex/agents/` entirely → ok with note (warn-free)
#   - malformed frontmatter / missing required keys → fail (MUST)
#   - duplicate `name:` across files → warn (advisory)
#
# Bash 3.2 compatible. No `yq` dependency — we parse the small subset of
# YAML that EIIS requires (top-level `key: value` plus `tools: [a, b]` /
# block-list `tools:` followed by `  - a` lines) using awk.
#
# Public function: eiis_check_codex <repo-dir-absolute> <target-version>

eiis_check_codex() {
  local dir="$1"
  local target_version="$2"

  # Skip codex checks for v1.0-only Eidolons.
  case "$target_version" in
    1.0|1.0.*|1)
      record "C0" "MUST" "ok" "codex checks skipped (target EIIS_VERSION ${target_version} predates v1.1)"
      return
      ;;
  esac

  local codex_dir="$dir/.codex/agents"
  if [ ! -d "$codex_dir" ]; then
    # §4.5 is optional — an Eidolon MAY ship Codex artefacts. Absence is fine.
    record "C0" "MUST" "ok" ".codex/agents/ not present (Codex surface is OPTIONAL in v1.1)"
    return
  fi

  # Enumerate .md files (bash 3.2: no readarray; use a loop).
  local f
  local found_any=0
  local saw_seen_names=""
  local dup_warned=0

  for f in "$codex_dir"/*.md; do
    # Glob may not match anything; guard.
    if [ ! -f "$f" ]; then
      continue
    fi
    found_any=1
    _eiis_check_codex_one_file "$f"

    # Collision check (§4.5.6, advisory).
    local fname_slug
    fname_slug="$(_eiis_codex_yaml_get "$f" name)"
    if [ -n "$fname_slug" ]; then
      case " $saw_seen_names " in
        *" $fname_slug "*)
          if [ "$dup_warned" -eq 0 ]; then
            record "C5" "SHOULD" "warn" \
              "duplicate name: '${fname_slug}' across multiple .codex/agents/*.md files (§4.5.6)" \
              "filename namespace prevents collisions; check frontmatter slugs"
            dup_warned=1
          fi
          ;;
        *)
          saw_seen_names="$saw_seen_names $fname_slug"
          ;;
      esac
    fi
  done

  if [ "$found_any" -eq 0 ]; then
    record "C0" "MUST" "ok" ".codex/agents/ exists but is empty (no subagent files to validate)"
    return
  fi
}

# --------------------------------------------------------------------------- #
# Per-file validation. Each file's record IDs are namespaced by basename so
# multiple files can be checked without ID collisions.
# --------------------------------------------------------------------------- #
_eiis_check_codex_one_file() {
  local f="$1"
  local base
  base="$(basename "$f" .md)"

  # C1 — frontmatter delimited by `---` (§4.5.2.1).
  if ! _eiis_codex_has_frontmatter "$f"; then
    record "C1:${base}" "MUST" "fail" \
      ".codex/agents/${base}.md missing YAML frontmatter (§4.5.2.1)"
    return
  fi
  record "C1:${base}" "MUST" "ok" \
    ".codex/agents/${base}.md has YAML frontmatter delimiters"

  # C2 — required `name:` (§4.5.2.2).
  local name_val
  name_val="$(_eiis_codex_yaml_get "$f" name)"
  if [ -z "$name_val" ]; then
    record "C2:${base}" "MUST" "fail" \
      ".codex/agents/${base}.md missing required 'name:' (§4.5.2.2)"
  else
    if printf '%s' "$name_val" | grep -Eq '^[a-z][a-z0-9-]*$'; then
      record "C2:${base}" "MUST" "ok" \
        ".codex/agents/${base}.md name='${name_val}'"
    else
      record "C2:${base}" "MUST" "fail" \
        ".codex/agents/${base}.md name='${name_val}' does not match ^[a-z][a-z0-9-]*$ (§4.5.2.2)"
    fi
  fi

  # C3 — required `description:` non-empty (§4.5.2.2).
  local desc_val
  desc_val="$(_eiis_codex_yaml_get "$f" description)"
  if [ -z "$desc_val" ]; then
    record "C3:${base}" "MUST" "fail" \
      ".codex/agents/${base}.md missing or empty 'description:' (§4.5.2.2)"
  else
    record "C3:${base}" "MUST" "ok" \
      ".codex/agents/${base}.md description present"
  fi

  # C4 — optional fields, structural sanity (§4.5.2.3).
  # `tools:` if present should be a YAML list (flow `[a, b]` or block `- a`).
  if _eiis_codex_yaml_has_key "$f" tools; then
    if _eiis_codex_tools_is_list "$f"; then
      record "C4-tools:${base}" "SHOULD" "ok" \
        ".codex/agents/${base}.md tools: is a list"
    else
      record "C4-tools:${base}" "MUST" "fail" \
        ".codex/agents/${base}.md tools: present but is not a YAML list (§4.5.2.3)"
    fi
  fi
  # `model:` if present must be a non-empty string. Scalar parser tolerates anything; just check non-empty.
  if _eiis_codex_yaml_has_key "$f" model; then
    local model_val
    model_val="$(_eiis_codex_yaml_get "$f" model)"
    if [ -z "$model_val" ]; then
      record "C4-model:${base}" "MUST" "fail" \
        ".codex/agents/${base}.md model: present but empty (§4.5.2.3)"
    else
      record "C4-model:${base}" "SHOULD" "ok" \
        ".codex/agents/${base}.md model='${model_val}'"
    fi
  fi
}

# --------------------------------------------------------------------------- #
# Tiny YAML helpers — scoped to the frontmatter region only.
# --------------------------------------------------------------------------- #

# Returns 0 iff the file begins with `---` and contains a closing `---`
# before the body (within the first 200 lines, conservatively).
_eiis_codex_has_frontmatter() {
  local f="$1"
  awk '
    BEGIN { ok = 0 }
    NR == 1 {
      if ($0 != "---") { exit 1 }
      next
    }
    NR > 1 && NR <= 200 {
      if ($0 == "---") { ok = 1; exit 0 }
    }
    NR > 200 { exit 1 }
    END { if (ok == 1) exit 0; else exit 1 }
  ' "$f"
}

# _eiis_codex_yaml_get <file> <key>
# Echoes the trimmed scalar value for the top-level key inside the frontmatter.
# Empty string if absent.
_eiis_codex_yaml_get() {
  local f="$1" key="$2"
  awk -v key="$key" '
    BEGIN { in_fm = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm {
      # Match top-level "key:" (no leading whitespace).
      pat = "^" key ":[[:space:]]*"
      if ($0 ~ pat) {
        v = $0
        sub(pat, "", v)
        # Strip surrounding double or single quotes if balanced.
        if (v ~ /^".*"$/) {
          v = substr(v, 2, length(v) - 2)
        } else if (v ~ /^'\''.*'\''$/) {
          v = substr(v, 2, length(v) - 2)
        }
        # Trim trailing whitespace.
        sub(/[[:space:]]+$/, "", v)
        print v
        exit
      }
    }
  ' "$f"
}

# _eiis_codex_yaml_has_key <file> <key>
# Returns 0 iff the top-level key appears in the frontmatter (even if value
# is empty / a list / a block).
_eiis_codex_yaml_has_key() {
  local f="$1" key="$2"
  awk -v key="$key" '
    BEGIN { in_fm = 0; found = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit (found ? 0 : 1) }
    in_fm {
      pat = "^" key ":"
      if ($0 ~ pat) { found = 1; exit 0 }
    }
    END { exit (found ? 0 : 1) }
  ' "$f"
}

# _eiis_codex_tools_is_list <file>
# Heuristic: tools: present in frontmatter, and either flow-style `[...]`
# on the same line, or block-list `- item` lines following.
_eiis_codex_tools_is_list() {
  local f="$1"
  awk '
    BEGIN { in_fm = 0; saw_tools = 0; is_list = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit (is_list ? 0 : 1) }
    in_fm {
      if ($0 ~ /^tools:[[:space:]]*\[.*\][[:space:]]*$/) {
        is_list = 1
        next
      }
      if ($0 ~ /^tools:[[:space:]]*$/) {
        saw_tools = 1
        next
      }
      if (saw_tools == 1) {
        if ($0 ~ /^[[:space:]]+-[[:space:]]/) {
          is_list = 1
        } else if ($0 ~ /^[[:space:]]/) {
          # Indented continuation — tolerate.
        } else {
          # Back to top-level key; stop list-mode.
          saw_tools = 0
        }
      }
    }
    END { exit (is_list ? 0 : 1) }
  ' "$f"
}
