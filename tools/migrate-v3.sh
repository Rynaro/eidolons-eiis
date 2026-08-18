#!/usr/bin/env bash
# Mechanically migrate a clean EIIS 1.x Eidolon repository to the v3 package shape.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() { printf 'Usage: %s REPO NAME VERSION METHODOLOGY SECURITY_JSON\n' "$0"; }

[ "$#" -eq 5 ] || { usage >&2; exit 2; }
REPO="$(cd "$1" && pwd)"
NAME="$2"
VERSION="$3"
METHODOLOGY="$4"
SECURITY_JSON="$5"

git -C "$REPO" diff --quiet
git -C "$REPO" diff --cached --quiet
jq -e 'type == "object"' <<<"$SECURITY_JSON" >/dev/null

if [ "$(git -C "$REPO" branch --show-current)" = "main" ]; then
  git -C "$REPO" switch -c agent/eiis-v3-self-contained
fi

if [ -f "$REPO/agent.md" ] && [ ! -f "$REPO/PERSONA.md" ]; then
  git -C "$REPO" mv agent.md PERSONA.md
fi

if [ -d "$REPO/skills" ]; then
  while IFS= read -r source; do
    slug="$(basename "$source" .md)"
    mkdir -p "$REPO/skills/$slug"
    git -C "$REPO" mv "skills/$slug.md" "skills/$slug/SKILL.md"
    while IFS= read -r text_file; do
      perl -pi -e "s#skills/\\Q${slug}\\E\\.md#skills/${slug}/SKILL.md#g" "$REPO/$text_file"
    done < <(git -C "$REPO" grep -Il "skills/$slug.md" -- ':!CHANGELOG.md' || true)
  done < <(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)
fi

while IFS= read -r text_file; do
  perl -pi -e 's#(?<![A-Za-z0-9_.-])agent\.md#PERSONA.md#g' "$REPO/$text_file"
done < <(git -C "$REPO" grep -Il 'agent\.md' -- ':!CHANGELOG.md' || true)

git -C "$REPO" rm -rf --ignore-unmatch .claude .codex hosts
git -C "$REPO" rm -rf --ignore-unmatch .eidolons-audit
git -C "$REPO" rm -f --ignore-unmatch AGENTS.md CLAUDE.md EIDOLONS.md
git -C "$REPO" rm -f --ignore-unmatch .github/copilot-instructions.md
git -C "$REPO" rm -rf --ignore-unmatch .github/instructions
git -C "$REPO" rm -f --ignore-unmatch examples/install.manifest.json schemas/install.manifest.v1.json

printf '3.0.0\n' > "$REPO/EIIS_VERSION"
cp "$ROOT/templates/eidolon-skeleton/install.sh" "$REPO/install.sh"
chmod +x "$REPO/install.sh"
mkdir -p "$REPO/schemas"
cp "$ROOT/schemas/package-manifest.v3.json" "$REPO/schemas/package-manifest.v3.json"
cp "$ROOT/schemas/install-receipt.v1.json" "$REPO/schemas/install-receipt.v1.json"
cp "$ROOT/templates/github-actions-eidolon-ci.yml" "$REPO/.github/workflows/eiis.yml"
sed -e "s/{{EIDOLON_NAME}}/$NAME/g" -e "s/{{METHODOLOGY}}/$METHODOLOGY/g" \
  "$ROOT/templates/eidolon-skeleton/INSTALL.md" > "$REPO/INSTALL.md"

skills_json='{}'
if [ -d "$REPO/skills" ]; then
  while IFS= read -r entry; do
    slug="$(basename "$(dirname "$entry")")"
    skills_json="$(jq --arg slug "$slug" --arg entry "skills/$slug/SKILL.md" \
      '. + {($slug): {entrypoint: $entry, resources: []}}' <<<"$skills_json")"
  done < <(find "$REPO/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | LC_ALL=C sort)
fi

resources_json='[]'
for resource in ECL_VERSION commands schemas templates contracts anchors bin tools docs mcp-server scripts CRYSTALIUM.md MISSION.md; do
  [ -e "$REPO/$resource" ] || continue
  resources_json="$(jq --arg resource "$resource" '. + [$resource]' <<<"$resources_json")"
done

jq -n \
  --arg name "$NAME" --arg version "$VERSION" --arg methodology "$METHODOLOGY" \
  --argjson skills "$skills_json" --argjson resources "$resources_json" \
  --argjson security "$SECURITY_JSON" \
  '{
    "$schema": "https://github.com/Rynaro/eidolons-eiis/blob/v3.0.0/schemas/package-manifest.v3.json",
    schema_version: "3.0", eiis_version: "3.0.0",
    name: $name, version: $version, methodology: $methodology,
    entrypoints: {persona: "PERSONA.md", spec: "SPEC.md"},
    skills: $skills, resources: $resources, security: $security
  }' > "$REPO/manifest.json"

printf 'Migrated %s@%s in %s\n' "$NAME" "$VERSION" "$REPO"
