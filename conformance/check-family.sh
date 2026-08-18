#!/usr/bin/env bash
# Verify that multiple Eidolon repositories share the EIIS v3 navigation baseline.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ "$#" -gt 0 ] || { printf 'Usage: %s REPO...\n' "$0" >&2; exit 2; }

failures=0
for repo_arg in "$@"; do
  repo="$(cd "$repo_arg" && pwd)"
  name="$(jq -r '.name // empty' "$repo/manifest.json" 2>/dev/null || true)"
  label="${name:-$(basename "$repo")}"
  bad=""

  for file in PERSONA.md SPEC.md manifest.json EIIS_VERSION install.sh README.md INSTALL.md; do
    [ -f "$repo/$file" ] || bad="${bad}${file} missing; "
  done
  [ "$(tr -d '[:space:]' < "$repo/EIIS_VERSION" 2>/dev/null || true)" = "3.0.0" ] \
    || bad="${bad}EIIS_VERSION is not 3.0.0; "
  [ ! -e "$repo/agent.md" ] || bad="${bad}agent.md present; "
  [ ! -e "$repo/EIDOLONS.md" ] || bad="${bad}package-local EIDOLONS.md present; "
  [ ! -d "$repo/hosts" ] || bad="${bad}package-local hosts/ present; "
  [ ! -d "$repo/.claude/agents" ] || bad="${bad}committed Claude adapters present; "
  [ ! -d "$repo/.github/instructions" ] || bad="${bad}committed Copilot adapters present; "
  find "$repo/skills" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print -quit 2>/dev/null \
    | grep -q . && bad="${bad}flat skill files present; "

  cmp -s "$repo/install.sh" "$ROOT/templates/eidolon-skeleton/install.sh" \
    || bad="${bad}installer differs from v3 baseline; "
  cmp -s "$repo/schemas/package-manifest.v3.json" "$ROOT/schemas/package-manifest.v3.json" \
    || bad="${bad}package schema differs; "
  cmp -s "$repo/schemas/install-receipt.v1.json" "$ROOT/schemas/install-receipt.v1.json" \
    || bad="${bad}receipt schema differs; "
  cmp -s "$repo/.github/workflows/eiis.yml" "$ROOT/templates/github-actions-eidolon-ci.yml" \
    || bad="${bad}EIIS workflow differs; "

  if [ -n "$bad" ]; then
    printf 'FAIL %-12s %s\n' "$label" "$bad"
    failures=$((failures + 1))
  else
    printf 'OK   %-12s shared v3 shape\n' "$label"
  fi
done

[ "$failures" -eq 0 ]
