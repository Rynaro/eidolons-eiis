#!/usr/bin/env bash
# Detect drift between the compact EIIS v3 contract and published artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACT="$ROOT/contract/eiis-3.0.yaml"

value() {
  awk -F ': *' -v key="$1" '$1 == key { print $2; exit }' "$CONTRACT" | tr -d '"'
}

VERSION="$(tr -d '[:space:]' < "$ROOT/EIIS_VERSION")"
[ "$(value version)" = "$VERSION" ]
[ -f "$ROOT/$(value package_schema)" ]
[ -f "$ROOT/$(value receipt_schema)" ]

grep -q 'persona: PERSONA.md' "$CONTRACT"
grep -q 'spec: SPEC.md' "$CONTRACT"
grep -q 'skill: skills/\*/SKILL.md' "$CONTRACT"
grep -q 'required_marker: "generated_by: eidolons"' "$CONTRACT"

for gate in V3-P1 V3-M1 V3-S1 V3-R1 V3-H1 V3-A1 V3-I1 V3-I2; do
  grep -q "$gate" "$ROOT/spec/eiis-3.0.md"
  grep -q "$gate" "$ROOT/conformance/lib/checks-v3.sh"
done

printf 'EIIS v3 contract and published artifacts agree.\n'
