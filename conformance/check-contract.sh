#!/usr/bin/env bash
# Detect drift between the compact EIIS v3 contract and published artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/EIIS_VERSION")"
SPEC_VER="$(printf '%s' "$VERSION" | cut -d. -f1-2)"
CONTRACT="$ROOT/contract/eiis-${SPEC_VER}.yaml"
SPEC="$ROOT/spec/eiis-${SPEC_VER}.md"

value() {
  awk -F ': *' -v key="$1" '$1 == key { print $2; exit }' "$CONTRACT" | tr -d '"'
}

[ -f "$CONTRACT" ]
[ -f "$SPEC" ]
[ "$(value version)" = "$VERSION" ]
[ -f "$ROOT/$(value package_schema)" ]
[ -f "$ROOT/$(value receipt_schema)" ]

grep -q 'persona: PERSONA.md' "$CONTRACT"
grep -q 'spec: SPEC.md' "$CONTRACT"
grep -q 'skill: skills/\*/SKILL.md' "$CONTRACT"
grep -q 'required_marker: "generated_by: eidolons"' "$CONTRACT"

for gate in V3-P1 V3-M1 V3-S1 V3-R1 V3-H1 V3-A1 V3-I1 V3-I2; do
  grep -q "$gate" "$SPEC"
  grep -q "$gate" "$ROOT/conformance/lib/checks-v3.sh"
done

# v3.1+ Cursor multi-surface gate is documented in the spec; checker stays
# presence-gated in the nexus (packages remain adapter-free per V3-A1).
if [ "$SPEC_VER" != "3.0" ]; then
  grep -q 'V3-A2' "$SPEC"
  grep -q 'host_adapter_paths:' "$CONTRACT"
  grep -q '\.cursor/agents/<name>\.md' "$CONTRACT"
  grep -q '\.cursor/skills/<name>-<skill>/SKILL.md' "$CONTRACT"
fi

printf 'EIIS v%s contract and published artifacts agree.\n' "$SPEC_VER"
