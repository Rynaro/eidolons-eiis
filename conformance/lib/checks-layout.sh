# shellcheck shell=bash
# EIIS §1 — Repo Layout checks. Sourced by check.sh.
#
# Public function: eiis_check_layout <repo-dir-absolute>
#
# Records L<n> results via the parent's `record` helper.

eiis_check_layout() {
  local dir="$1"

  # L1 — agent.md (MUST, §1.1)
  if [ -f "$dir/agent.md" ]; then
    record "L1" "MUST" "ok" "agent.md exists"
  else
    record "L1" "MUST" "fail" "agent.md exists"
  fi

  # L2 — AGENTS.md (MUST)
  if [ -f "$dir/AGENTS.md" ]; then
    record "L2" "MUST" "ok" "AGENTS.md exists"
  else
    record "L2" "MUST" "fail" "AGENTS.md exists"
  fi

  # L3 — CLAUDE.md (MUST)
  if [ -f "$dir/CLAUDE.md" ]; then
    record "L3" "MUST" "ok" "CLAUDE.md exists"
  else
    record "L3" "MUST" "fail" "CLAUDE.md exists"
  fi

  # L4 — README.md (MUST)
  if [ -f "$dir/README.md" ]; then
    record "L4" "MUST" "ok" "README.md exists"
  else
    record "L4" "MUST" "fail" "README.md exists"
  fi

  # L5 — install.sh exists and is bash-runnable (MUST, §1.1 + §1.2)
  if [ -f "$dir/install.sh" ]; then
    if [ -x "$dir/install.sh" ] || head -n 1 "$dir/install.sh" | grep -q '^#!.*bash' 2>/dev/null; then
      record "L5" "MUST" "ok" "install.sh exists and is runnable"
    else
      record "L5" "MUST" "fail" "install.sh exists but is neither executable nor a bash script"
    fi
  else
    record "L5" "MUST" "fail" "install.sh exists"
  fi

  # L6 — install.sh first line shebang (informative SHOULD, no separate
  # gate — folded into L5).

  # L7 — EIIS_VERSION file (MUST, warn-only in v1.0; D-6)
  if [ -f "$dir/EIIS_VERSION" ]; then
    local content
    content="$(head -n 1 "$dir/EIIS_VERSION" | tr -d '[:space:]')"
    if printf '%s' "$content" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
      record "L7" "MUST" "ok" "EIIS_VERSION file present and well-formed (${content})"
    else
      record "L7" "MUST" "fail" "EIIS_VERSION present but malformed: '${content}'"
    fi
  else
    # D-6 grandfather window: warn-only in v1.0.
    record "L7" "MUST" "warn" "EIIS_VERSION file (D-6)" \
      "grandfathered until 2027-04-24"
  fi

  # L8 — CHANGELOG.md (SHOULD, §1.4)
  if [ -f "$dir/CHANGELOG.md" ]; then
    record "L8" "SHOULD" "ok" "CHANGELOG.md exists"
  else
    record "L8" "SHOULD" "fail" "CHANGELOG.md exists"
  fi

  # L9 — vendored manifest schema (SHOULD, §1.5)
  if [ -f "$dir/schemas/install.manifest.v1.json" ]; then
    record "L9" "SHOULD" "ok" "vendored schemas/install.manifest.v1.json present"
  else
    record "L9" "SHOULD" "fail" "vendored schemas/install.manifest.v1.json missing"
  fi
}
