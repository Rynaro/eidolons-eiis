#!/usr/bin/env bash
# Apply the shared human-facing navigation and CI surface to a migrated package.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ "$#" -eq 3 ] || { printf 'Usage: %s REPO NAME METHODOLOGY\n' "$0" >&2; exit 2; }
REPO="$(cd "$1" && pwd)"
NAME="$2"
METHODOLOGY="$3"

cp "$ROOT/templates/github-actions-eidolon-ci.yml" "$REPO/.github/workflows/eiis.yml"
sed -e "s/{{EIDOLON_NAME}}/$NAME/g" -e "s/{{METHODOLOGY}}/$METHODOLOGY/g" \
  "$ROOT/templates/eidolon-skeleton/INSTALL.md" > "$REPO/INSTALL.md"

for file in README.md PERSONA.md SPEC.md; do
  [ -f "$REPO/$file" ] || continue
  perl -pi -e 's/EIIS v?1\.[0-9]+/EIIS 3.0/g' "$REPO/$file"
done

if ! grep -q '<!-- eiis-v3-package:start -->' "$REPO/README.md"; then
  {
    printf '\n<!-- eiis-v3-package:start -->\n'
    printf '## EIIS v3 package\n\n'
    printf 'This repository has the same self-contained package shape as every roster Eidolon:\n\n'
    printf -- '- `PERSONA.md` — bounded identity, triggers, authority, refusals, and handoffs.\n'
    printf -- '- `SPEC.md` — the authoritative methodology.\n'
    printf -- '- `skills/<methodology>/SKILL.md` — unique skill discovery entrypoints.\n'
    printf -- '- `manifest.json` — immutable package metadata and resource inventory.\n'
    printf -- '- `install.sh` — package-only installer; the nexus owns vendor adapters.\n\n'
    printf 'See [INSTALL.md](INSTALL.md) for nexus and standalone installation.\n'
    printf '<!-- eiis-v3-package:end -->\n'
  } >> "$REPO/README.md"
fi
