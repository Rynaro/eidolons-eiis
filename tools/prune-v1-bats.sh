#!/usr/bin/env bash
# Remove per-repository EIIS 1.x implementation assertions now owned by v3 conformance.
set -euo pipefail

[ "$#" -eq 1 ] || { printf 'Usage: %s REPO\n' "$0" >&2; exit 2; }
REPO="$(cd "$1" && pwd)"

for file in "$REPO"/tests/*.bats; do
  [ -f "$file" ] || continue
  tmp="$(mktemp)"
  awk '
    BEGIN { dropping = 0 }
    /^@test "/ {
      obsolete = ($0 ~ /(install\.sh|install manifest|install\.manifest|install produces|install target|install wires|install copies|install records|install with claude-code|non-interactive install|vendor SKILL|manifest skills|manifest files_written|stamp:|EIIS_VERSION|AGENTS\.md|CLAUDE\.md|hosts\/|manifest schema|examples manifest|version:)/)
      if (obsolete) { dropping = 1; next }
    }
    dropping && /^}$/ { dropping = 0; next }
    !dropping { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
done
