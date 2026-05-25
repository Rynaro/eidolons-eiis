#!/usr/bin/env bash
# {{METHODOLOGY}} installer — EIIS v1.3 conformant
# Usage: bash install.sh [OPTIONS]
set -u
set -o pipefail

EIDOLON_NAME="{{EIDOLON_NAME}}"
EIDOLON_SLUG="{{EIDOLON_SLUG}}"   # lowercase slug, e.g. "my-eidolon" (same as EIDOLON_NAME unless it differs)
EIDOLON_VERSION="{{VERSION}}"
METHODOLOGY="{{METHODOLOGY}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------- #
# Defaults
# --------------------------------------------------------------------------- #
TARGET="./.eidolons/${EIDOLON_NAME}"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false
SHARED_DISPATCH=false

# --------------------------------------------------------------------------- #
# Help
# --------------------------------------------------------------------------- #
usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Install ${METHODOLOGY} v${EIDOLON_VERSION} into the current consumer project.

Options:
  --target DIR            Target install dir (default: ${TARGET})
  --hosts LIST            claude-code,copilot,cursor,opencode,codex,
                          all,auto,none (default: auto)
  --shared-dispatch       Compose marker-bounded section in root AGENTS.md /
                          CLAUDE.md / .github/copilot-instructions.md.
  --no-shared-dispatch    Skip root composition (default).
  --force                 Overwrite without prompting.
  --dry-run               Print actions without writing files.
  --non-interactive       No prompts; fail on ambiguity.
  --manifest-only         Only emit install.manifest.json (no file copies).
  --version               Print Eidolon version and exit 0.
  -h, --help              Show this help and exit 0.

EIIS v1.3 conformant. See:
  https://github.com/Rynaro/eidolons-eiis/blob/main/spec/eiis-1.3.md
EOF
}

# --------------------------------------------------------------------------- #
# Argument parsing
# --------------------------------------------------------------------------- #
while [ $# -gt 0 ]; do
  case "$1" in
    --target)               TARGET="$2"; shift 2 ;;
    --hosts)                HOSTS="$2"; shift 2 ;;
    --shared-dispatch)      SHARED_DISPATCH=true; shift ;;
    --no-shared-dispatch)   SHARED_DISPATCH=false; shift ;;
    --force)                FORCE=true; shift ;;
    --dry-run)              DRY_RUN=true; shift ;;
    --non-interactive)      NON_INTERACTIVE=true; shift ;;
    --manifest-only)        MANIFEST_ONLY=true; shift ;;
    --version)              echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)              usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------- #
# Utilities
# --------------------------------------------------------------------------- #
log()  { echo "[${EIDOLON_NAME}] $*"; }
warn() { echo "[${EIDOLON_NAME}] WARN: $*" >&2; }

do_action() {
  local desc="$1"; shift
  if [ "$DRY_RUN" = "true" ]; then
    echo "  [dry-run] ${desc}"
  else
    "$@"
  fi
}

sha256_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  else
    echo "0000000000000000000000000000000000000000000000000000000000000000"
  fi
}

# --------------------------------------------------------------------------- #
# Host detection
# --------------------------------------------------------------------------- #
detect_hosts() {
  local detected=""
  if [ -f "CLAUDE.md" ] || [ -d ".claude" ]; then detected="${detected}claude-code,"; fi
  if [ -d ".github" ]; then detected="${detected}copilot,"; fi
  if [ -d ".cursor" ] || [ -f ".cursorrules" ]; then detected="${detected}cursor,"; fi
  if [ -d ".opencode" ]; then detected="${detected}opencode,"; fi
  # Codex (EIIS v1.1 §4.5): .codex/ is the definitive Codex-only signal;
  # AGENTS.md alone (without .github/) also indicates Codex.
  if [ -d ".codex" ]; then detected="${detected}codex,"; fi
  if [ -f "AGENTS.md" ] && [ ! -d ".github" ] && [ ! -d ".codex" ]; then
    detected="${detected}codex,"
  fi
  echo "${detected%,}"
}

if [ "$HOSTS" = "auto" ]; then
  HOSTS="$(detect_hosts)"
  if [ -z "$HOSTS" ]; then
    warn "No host config detected. Using raw install only."
    HOSTS="raw"
  fi
elif [ "$HOSTS" = "all" ]; then
  HOSTS="claude-code,copilot,cursor,opencode,codex"
fi

hosts_include() {
  case ",${HOSTS}," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Validate the host list (--hosts LIST values per EIIS §2.1).
IFS=',' read -ra _HOST_ARRAY <<< "$HOSTS"
for _h in "${_HOST_ARRAY[@]}"; do
  case "$_h" in
    claude-code|copilot|cursor|opencode|codex|raw|none|"") : ;;
    *) echo "Invalid --hosts value: $_h" >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------- #
# Idempotency check
# --------------------------------------------------------------------------- #
EXISTING_MANIFEST="${TARGET}/install.manifest.json"
if [ -f "$EXISTING_MANIFEST" ] && [ "$FORCE" != "true" ]; then
  if [ "$NON_INTERACTIVE" = "true" ]; then
    echo "Already installed at ${TARGET}. Pass --force to overwrite." >&2
    exit 3
  fi
  read -rp "[${EIDOLON_NAME}] Already installed at ${TARGET}. Overwrite? [y/N] " confirm
  case "$confirm" in
    y|Y|yes|YES) : ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# --------------------------------------------------------------------------- #
# Announce
# --------------------------------------------------------------------------- #
log "Installing ${METHODOLOGY} v${EIDOLON_VERSION} -> ${TARGET}"
log "Hosts: ${HOSTS}"
[ "$DRY_RUN" = "true" ] && log "Mode: dry-run (no files written)"
[ "$MANIFEST_ONLY" = "true" ] && log "Mode: manifest-only"

# --------------------------------------------------------------------------- #
# Directory creation
# --------------------------------------------------------------------------- #
FILES_WRITTEN=()

maybe_mkdir() {
  do_action "mkdir -p $1" mkdir -p "$1"
}

maybe_mkdir "${TARGET}"

# --------------------------------------------------------------------------- #
# Copy methodology files
# --------------------------------------------------------------------------- #
copy_file() {
  # copy_file <src-relative-to-script> <dst> <role>
  local src="$1" dst="$2" role="$3"
  do_action "copy ${src} -> ${dst}" cp "${SCRIPT_DIR}/${src}" "${dst}"
  if [ "$DRY_RUN" != "true" ] && [ -f "${dst}" ]; then
    local chk
    chk="$(sha256_file "${dst}")"
    FILES_WRITTEN+=("{\"path\":\"${dst}\",\"sha256\":\"${chk}\",\"role\":\"${role}\",\"mode\":\"created\"}")
  fi
}

# --------------------------------------------------------------------------- #
# wire_skill — EIIS v1.3 §4.2.4 dual-write helper
#
# Copies a skill file to:
#   - source-of-truth: ${TARGET}/skills/<skill>.md
#   - host vendor copy: .claude/skills/${EIDOLON_SLUG}-<skill>/SKILL.md
#     (only when claude-code is wired)
#
# Bash 3.2 compatible. See EIIS v1.3 Appendix A for the canonical reference.
# --------------------------------------------------------------------------- #
wire_skill() {
  local skill="$1"
  local src="${SCRIPT_DIR}/skills/${skill}.md"
  local dst_src="${TARGET}/skills/${skill}.md"
  local dst_vendor=".claude/skills/${EIDOLON_SLUG}-${skill}/SKILL.md"

  if [ ! -f "${src}" ]; then
    echo "ERROR: skill source not found: ${src}" >&2
    exit 1
  fi

  # Source-of-truth write (host-independent).
  do_action "mkdir -p $(dirname "${dst_src}")" mkdir -p "$(dirname "${dst_src}")"
  do_action "copy skills/${skill}.md -> ${dst_src}" cp "${src}" "${dst_src}"
  if [ "$DRY_RUN" != "true" ] && [ -f "${dst_src}" ]; then
    local chk_src
    chk_src="$(sha256_file "${dst_src}")"
    FILES_WRITTEN+=("{\"path\":\"${dst_src}\",\"sha256\":\"${chk_src}\",\"role\":\"skill\",\"mode\":\"created\"}")
  fi

  # Vendor copy (claude-code host only, per EIIS v1.3 §4.2.4.4).
  if hosts_include "claude-code"; then
    do_action "mkdir -p $(dirname "${dst_vendor}")" mkdir -p "$(dirname "${dst_vendor}")"
    do_action "copy skills/${skill}.md -> ${dst_vendor}" cp "${src}" "${dst_vendor}"
    if [ "$DRY_RUN" != "true" ] && [ -f "${dst_vendor}" ]; then
      local chk_vendor
      chk_vendor="$(sha256_file "${dst_vendor}")"
      FILES_WRITTEN+=("{\"path\":\"${dst_vendor}\",\"sha256\":\"${chk_vendor}\",\"role\":\"skill\",\"mode\":\"created\"}")
    fi
  fi
}

if [ "$MANIFEST_ONLY" != "true" ]; then
  copy_file "agent.md"   "${TARGET}/agent.md"   "entry-point"
  copy_file "AGENTS.md"  "${TARGET}/AGENTS.md"  "entry-point"
  copy_file "CLAUDE.md"  "${TARGET}/CLAUDE.md"  "entry-point"

  # EIIS v1.3 §1.8 — canonical full-spec file MUST be named SPEC.md.
  copy_file "SPEC.md"    "${TARGET}/SPEC.md"    "spec"

  # EIIS v1.3 §4.2.4 — dual-write each skill. Replace with your skill slugs:
  # wire_skill "planning"
  # wire_skill "verification"
fi

# --------------------------------------------------------------------------- #
# Marker-aware shared-dispatch helper (EIIS §4.1).
#
# Owns a marker-bounded region in a composable dispatch file. If the region
# already exists, rewrites its body in place. Otherwise appends a new block.
# Idempotent by construction.
# --------------------------------------------------------------------------- #
upsert_eidolon_block() {
  # upsert_eidolon_block <dst> <content> <role>
  local dst="$1" content="$2" role="$3"
  local start="<!-- eidolon:${EIDOLON_NAME} start -->"
  local end="<!-- eidolon:${EIDOLON_NAME} end -->"

  if [ "$DRY_RUN" = "true" ]; then
    local action="append"
    if [ -f "$dst" ] && grep -qF "$start" "$dst" 2>/dev/null; then
      action="rewrite"
    fi
    echo "  [dry-run] ${action} eidolon:${EIDOLON_NAME} block in ${dst}"
    return
  fi

  mkdir -p "$(dirname "$dst")" 2>/dev/null || true

  if [ -L "$dst" ]; then
    rm -f "$dst"
  fi

  local content_file mode tmp
  content_file="$(mktemp)"
  printf '%s\n' "$content" > "$content_file"

  if [ -f "$dst" ] && grep -qF "$start" "$dst" 2>/dev/null; then
    mode="rewritten"
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" -v cf="$content_file" '
      BEGIN { in_block = 0 }
      $0 == start {
        print start
        while ((getline line < cf) > 0) print line
        close(cf)
        in_block = 1
        next
      }
      $0 == end {
        print end
        in_block = 0
        next
      }
      !in_block { print }
    ' "$dst" > "$tmp"
    mv "$tmp" "$dst"
  elif [ -f "$dst" ]; then
    mode="appended"
    {
      printf '\n%s\n' "$start"
      cat "$content_file"
      printf '%s\n' "$end"
    } >> "$dst"
  else
    mode="created"
    {
      printf '%s\n' "$start"
      cat "$content_file"
      printf '%s\n' "$end"
    } > "$dst"
  fi

  rm -f "$content_file"

  local chk
  chk="$(sha256_file "$dst")"
  FILES_WRITTEN+=("{\"path\":\"${dst}\",\"sha256\":\"${chk}\",\"role\":\"${role}\",\"mode\":\"${mode}\"}")
}

# --------------------------------------------------------------------------- #
# Shared-dispatch composition
# --------------------------------------------------------------------------- #
SHARED_BLOCK="## ${METHODOLOGY} (v${EIDOLON_VERSION})

Entry: \`${TARGET}/agent.md\`
Spec:  \`${TARGET}/AGENTS.md\`

See \`${TARGET}/agent.md\` for P0 rules and the phase pipeline."

if [ "$MANIFEST_ONLY" != "true" ] && [ "$SHARED_DISPATCH" = "true" ]; then
  upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK" "dispatch"
  if hosts_include "claude-code"; then
    upsert_eidolon_block "CLAUDE.md" "$SHARED_BLOCK" "dispatch"
  fi
  if hosts_include "copilot"; then
    upsert_eidolon_block ".github/copilot-instructions.md" "$SHARED_BLOCK" "dispatch"
  fi
fi

# EIIS v1.1 §4.1.0 — root AGENTS.md is co-owned by `copilot` and `codex`.
# When `codex` is wired, we MUST write the marker block into root AGENTS.md
# regardless of --shared-dispatch (Codex's primary instruction surface).
if [ "$MANIFEST_ONLY" != "true" ] && [ "$SHARED_DISPATCH" != "true" ] \
     && hosts_include "codex"; then
  upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK" "dispatch"
fi

# --------------------------------------------------------------------------- #
# Per-host dispatch files (filename namespace; EIIS §4.2)
# --------------------------------------------------------------------------- #
write_per_host_dispatch() {
  # write_per_host_dispatch <dst> <content>
  local dst="$1" content="$2"
  if [ "$DRY_RUN" = "true" ]; then
    echo "  [dry-run] write ${dst}"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  printf '%s\n' "$content" > "$dst"
  local chk
  chk="$(sha256_file "$dst")"
  FILES_WRITTEN+=("{\"path\":\"${dst}\",\"sha256\":\"${chk}\",\"role\":\"dispatch\",\"mode\":\"created\"}")
}

if [ "$MANIFEST_ONLY" != "true" ]; then
  CLAUDE_AGENT="---
name: ${EIDOLON_NAME}
description: ${METHODOLOGY} methodology agent.
tools: Read, Grep, Glob
---

# ${METHODOLOGY}

See \`${TARGET}/AGENTS.md\` for full methodology rules. Always-loaded
profile: \`${TARGET}/agent.md\`."

  COPILOT_INSTR="---
applyTo: \"**\"
description: \"${METHODOLOGY} methodology\"
---

See \`${TARGET}/AGENTS.md\` for full rules."

  CURSOR_RULE="---
description: \"${METHODOLOGY} methodology\"
alwaysApply: false
---

See \`${TARGET}/agent.md\` for the full ${METHODOLOGY} specification."

  OPENCODE_AGENT="---
mode: primary
description: \"${METHODOLOGY} methodology agent\"
---

See \`${TARGET}/AGENTS.md\` for full rules."

  # EIIS v1.1 §4.5 — Codex subagent file. Frontmatter contract:
  # required `name` (slug) + `description`; optional `tools`, `model`.
  # Source: https://developers.openai.com/codex/subagents
  CODEX_AGENT="---
name: ${EIDOLON_NAME}
description: ${METHODOLOGY} methodology subagent for Codex.
---

# ${METHODOLOGY} — Codex subagent

See \`${TARGET}/agent.md\` for the canonical methodology and
\`${TARGET}/AGENTS.md\` for the full ruleset."

  if hosts_include "claude-code"; then
    write_per_host_dispatch ".claude/agents/${EIDOLON_NAME}.md" "$CLAUDE_AGENT"
  fi
  if hosts_include "copilot"; then
    write_per_host_dispatch ".github/instructions/${EIDOLON_NAME}.instructions.md" "$COPILOT_INSTR"
  fi
  if hosts_include "cursor"; then
    write_per_host_dispatch ".cursor/rules/${EIDOLON_NAME}.mdc" "$CURSOR_RULE"
  fi
  if hosts_include "opencode"; then
    write_per_host_dispatch ".opencode/agents/${EIDOLON_NAME}.md" "$OPENCODE_AGENT"
  fi
  if hosts_include "codex"; then
    write_per_host_dispatch ".codex/agents/${EIDOLON_NAME}.md" "$CODEX_AGENT"
  fi
fi

# --------------------------------------------------------------------------- #
# Token budget check (EIIS §2.4 exit code 4)
# --------------------------------------------------------------------------- #
AGENT_MD_PATH="${TARGET}/agent.md"
if [ -f "$AGENT_MD_PATH" ]; then
  WORD_COUNT=$(wc -w < "$AGENT_MD_PATH")
elif [ -f "${SCRIPT_DIR}/agent.md" ]; then
  WORD_COUNT=$(wc -w < "${SCRIPT_DIR}/agent.md")
else
  WORD_COUNT=0
fi
AGENT_TOKENS=$(awk "BEGIN {printf \"%d\", ${WORD_COUNT}/0.75}")

if [ "$AGENT_TOKENS" -gt 1000 ]; then
  warn "agent.md exceeds 1000-token budget (estimated ${AGENT_TOKENS} tokens)."
  if [ "$NON_INTERACTIVE" = "true" ]; then
    echo "Error: agent.md token budget exceeded in --non-interactive mode." >&2
    exit 4
  fi
fi

# --------------------------------------------------------------------------- #
# Write install.manifest.json (EIIS §3)
# --------------------------------------------------------------------------- #
INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build hosts_wired JSON array from the comma-separated HOSTS.
HOSTS_JSON=""
IFS=',' read -ra _HW <<< "$HOSTS"
for _h in "${_HW[@]}"; do
  case "$_h" in
    "" | "none") continue ;;
  esac
  if [ -z "$HOSTS_JSON" ]; then
    HOSTS_JSON="\"${_h}\""
  else
    HOSTS_JSON="${HOSTS_JSON},\"${_h}\""
  fi
done

FILES_JSON=""
if [ "${#FILES_WRITTEN[@]}" -gt 0 ]; then
  FILES_JSON="$(printf '%s,' "${FILES_WRITTEN[@]}" | sed 's/,$//')"
fi

MANIFEST_PATH="${TARGET}/install.manifest.json"

if [ "$DRY_RUN" != "true" ]; then
  mkdir -p "${TARGET}"
  cat > "${MANIFEST_PATH}" <<MANIFEST_EOF
{
  "eidolon": "${EIDOLON_NAME}",
  "version": "${EIDOLON_VERSION}",
  "methodology": "${METHODOLOGY}",
  "installed_at": "${INSTALLED_AT}",
  "target": "${TARGET}",
  "hosts_wired": [${HOSTS_JSON}],
  "files_written": [${FILES_JSON}],
  "token_budget": {
    "entry": ${AGENT_TOKENS},
    "working_set_target": 1000
  }
}
MANIFEST_EOF
  log "Manifest: ${MANIFEST_PATH}"
fi

# --------------------------------------------------------------------------- #
# Success banner
# --------------------------------------------------------------------------- #
echo ""
echo "${METHODOLOGY} v${EIDOLON_VERSION} installed -> ${TARGET}"
echo "agent.md: ${AGENT_TOKENS} tokens (budget: <=1000)"
echo "Hosts wired: ${HOSTS}"
