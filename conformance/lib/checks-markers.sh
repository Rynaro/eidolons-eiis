# shellcheck shell=bash
# EIIS §4 — Host wiring conventions. Sourced by check.sh.
#
# Strategy: static analysis on install.sh. We look for the marker
# convention strings. If install.sh writes to root CLAUDE.md, AGENTS.md,
# or .github/copilot-instructions.md, that write MUST be inside a
# marker-bounded block (§4.1.3). Bare appends without markers (drift D-4)
# are a hard fail from v1.0.
#
# Detection heuristic:
#   - Find lines that redirect to the three shared-dispatch files
#     (`>> CLAUDE.md`, `> AGENTS.md`, etc.).
#   - For each, look in surrounding context for `<!-- eidolon:` or for a
#     call to a helper (`upsert_eidolon_block`, `marker_block`, etc.).
#
# This is heuristic. False positives possible if the installer writes
# to those files in a unique way the regex doesn't catch; false negatives
# possible if it writes via an alias. We err on the side of warning
# rather than silently passing.
#
# Public function: eiis_check_markers <repo-dir-absolute>

eiis_check_markers() {
  local dir="$1"
  local script="$dir/install.sh"

  if [ ! -f "$script" ]; then
    record "K0" "MUST" "fail" "install.sh missing — marker checks skipped"
    return
  fi

  # K1 — installer references the EIIS marker convention somewhere.
  if grep -q '<!-- eidolon:' "$script"; then
    record "K1" "MUST" "ok" "installer uses <!-- eidolon:<name> --> markers"
  else
    # If the installer doesn't write to any shared-dispatch file at all,
    # that's fine — a per-host-only installer is permitted (§4.1 only
    # binds when --shared-dispatch is set).
    if _writes_shared_dispatch "$script"; then
      record "K1" "MUST" "fail" "installer writes to shared-dispatch files but has no eidolon marker (D-4)"
    else
      record "K1" "MUST" "ok" "installer does not write to shared-dispatch files (markers not required)"
    fi
  fi

  # K2 — Detect bare append to CLAUDE.md / AGENTS.md /
  # .github/copilot-instructions.md without nearby markers.
  _check_marker_target "$script" "K2" "CLAUDE.md"
  _check_marker_target "$script" "K3" "AGENTS.md"
  _check_marker_target "$script" "K4" ".github/copilot-instructions.md"

  # K5 — per-host dispatch file naming convention (§4.2). We check that
  # if the installer writes to .claude/agents/, .opencode/agents/, etc.,
  # the file is named <eidolon>.md (matching the manifest slug).
  # This is an advisory check — we can't easily extract the slug
  # statically, so we just verify the directory is touched.
  if grep -Eq '\.claude/agents/[^/]+\.md' "$script"; then
    record "K5" "MUST" "ok" "installer writes a .claude/agents/ dispatch file"
  else
    if grep -q 'claude-code' "$script"; then
      record "K5" "MUST" "warn" "installer mentions claude-code but no .claude/agents/<name>.md write detected" \
        "static analysis cannot prove dispatch file is written"
    else
      record "K5" "SHOULD" "ok" "no claude-code wiring (skipped)"
    fi
  fi

  if grep -Eq '\.opencode/agents/[^/]+\.md' "$script"; then
    record "K6" "SHOULD" "ok" "installer writes a .opencode/agents/ dispatch file"
  else
    if grep -q 'opencode' "$script"; then
      record "K6" "SHOULD" "warn" "installer mentions opencode but no .opencode/agents/<name>.md write detected" \
        "static analysis cannot prove dispatch file is written"
    else
      record "K6" "SHOULD" "ok" "no opencode wiring (skipped)"
    fi
  fi
}

_writes_shared_dispatch() {
  # _writes_shared_dispatch <script>
  # Returns 0 if the script appears to write to any of the three
  # shared-dispatch files in §4.1.
  local script="$1"
  grep -Eq '(>>|>)[[:space:]]*"?(\./)?(CLAUDE\.md|AGENTS\.md|\.github/copilot-instructions\.md)' "$script"
}

_check_marker_target() {
  # _check_marker_target <script> <id> <target-file>
  local script="$1" id="$2" target="$3"

  # Find lines that redirect (>> or >) to the target.
  local writes
  writes="$(grep -nE "(>>|>)[[:space:]]*\"?(\./)?${target//./\\.}" "$script" || true)"

  if [ -z "$writes" ]; then
    record "$id" "MUST" "ok" "installer does not write to ${target}"
    return
  fi

  # For each write, check whether the surrounding 30 lines reference
  # the marker convention or a known marker-writing helper.
  local violation=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local lineno
    lineno="${line%%:*}"
    local start=$((lineno > 30 ? lineno - 30 : 1))
    local end=$((lineno + 5))
    if ! sed -n "${start},${end}p" "$script" \
         | grep -qE '<!-- eidolon:|upsert_eidolon_block'; then
      violation=1
      break
    fi
  done <<EOF
$writes
EOF

  if [ "$violation" -eq 0 ]; then
    record "$id" "MUST" "ok" "writes to ${target} are inside marker-bounded blocks"
  else
    record "$id" "MUST" "fail" "K-marker-missing-${target%%.*} — bare write to ${target} without eidolon marker (D-4)"
  fi
}
