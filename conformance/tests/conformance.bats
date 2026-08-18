#!/usr/bin/env bats
# EIIS conformance checker — self-test suite.

setup() {
  EIIS_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  CHECK="$EIIS_ROOT/conformance/check.sh"
  FIXTURES="$EIIS_ROOT/conformance/tests/fixtures"
}

@test "machine-readable v3 contract matches schemas, spec, and checker" {
  run bash "$EIIS_ROOT/conformance/check-contract.sh"
  [ "$status" -eq 0 ]
}

# --- fixtures ------------------------------------------------------------- #

@test "eidolon-conformant fixture exits 0" {
  run bash "$CHECK" "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
}

@test "eidolon-missing-file fixture exits 2 (L1 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-missing-file"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] L1'
}

@test "eidolon-bad-manifest fixture exits 2 (M7 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-bad-manifest"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] M7'
}

@test "eidolon-no-markers fixture exits 2 (K2 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-no-markers"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q 'K-marker-missing'
}

@test "eidolon-not-idempotent fixture exits 2" {
  run bash "$CHECK" "$FIXTURES/eidolon-not-idempotent"
  [ "$status" -eq 2 ]
}

# --- v1.1 codex addendum (§4.5) ------------------------------------------- #

@test "eidolon-codex-conformant fixture exits 0" {
  run bash "$CHECK" "$FIXTURES/eidolon-codex-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *C1:conformant'
  echo "$output" | grep -q "name='conformant'"
}

@test "eidolon-codex-bad-frontmatter fixture exits 2 (C3 fails on missing description)" {
  run bash "$CHECK" "$FIXTURES/eidolon-codex-bad-frontmatter"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *C3:conformant'
}

@test "v1.0-only fixtures still exit 0 (codex skipped)" {
  run bash "$CHECK" "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  # C0 records the skip note for v1.0 targets.
  echo "$output" | grep -q '\[OK\] *C0'
  echo "$output" | grep -q 'codex checks skipped'
}

@test "--target-version 1.1 explicit on conformant v1.0 fixture runs codex (no .codex/ → ok)" {
  run bash "$CHECK" --target-version 1.1 "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *C0'
  echo "$output" | grep -q '\.codex/agents/ not present'
}

# --- option parsing ------------------------------------------------------- #

@test "--help exits 0" {
  run bash "$CHECK" --help
  [ "$status" -eq 0 ]
}

@test "--version exits 0 with output" {
  run bash "$CHECK" --version
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "missing repo arg exits 1" {
  run bash "$CHECK"
  [ "$status" -eq 1 ]
}

@test "non-existent repo dir exits 1" {
  run bash "$CHECK" /nonexistent/path/that/does/not/exist
  [ "$status" -eq 1 ]
}

@test "unknown flag exits 1" {
  run bash "$CHECK" --unknown-flag "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 1 ]
}

# --- output modes --------------------------------------------------------- #

@test "--json output is valid JSON" {
  run bash "$CHECK" --json "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | jq empty
}

@test "--json output contains required fields" {
  run bash "$CHECK" --json "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.eidolon_repo and .eiis_version_targeted and .results and (.exit_code | type == "number")'
}

@test "--json output exit_code matches checker exit" {
  run bash "$CHECK" --json "$FIXTURES/eidolon-missing-file"
  [ "$status" -eq 2 ]
  json_exit="$(echo "$output" | jq -r .exit_code)"
  [ "$json_exit" -eq 2 ]
}

@test "--level=MUST suppresses passing SHOULD lines" {
  run bash "$CHECK" --level=MUST "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q '\[OK\] .* SHOULD'
}

# --- target version resolution -------------------------------------------- #

@test "--target-version 1.0 explicit works" {
  run bash "$CHECK" --target-version 1.0 "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
}

@test "EIIS_VERSION file is read for default target version" {
  run bash "$CHECK" "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'Target EIIS:   1.0'
}

# --- live Eidolon smoke (skip when sibling repos not present) ------------- #

@test "live ATLAS exits 0 or 4 (D-6 grandfathered)" {
  if [ ! -d "/Users/henrique/workspace/oss/agents/ATLAS" ]; then
    skip "ATLAS sibling clone not present"
  fi
  run bash "$CHECK" "/Users/henrique/workspace/oss/agents/ATLAS"
  [ "$status" -eq 0 ] || [ "$status" -eq 4 ]
}

@test "live FORGE exits 2 (D-4 hard fail) — pending FORGE patch wave" {
  if [ ! -d "/Users/henrique/workspace/oss/agents/FORGE" ]; then
    skip "FORGE sibling clone not present"
  fi
  run bash "$CHECK" "/Users/henrique/workspace/oss/agents/FORGE"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q 'D-4'
}

# --- v1.3 SPEC.md + skills dual-write gates (§1.8, §4.2.4) --------------- #

@test "eidolon-v13-conformant fixture exits 0 (S1, S2, K-series all pass)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v13-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *S1'
  echo "$output" | grep -q '\[OK\] *S2'
  echo "$output" | grep -q '\[OK\] *K1'
  echo "$output" | grep -q '\[OK\] *K2'
}

@test "eidolon-v13-no-specfile fixture exits 2 (S1 and S2 fail at v1.3)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v13-no-specfile"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *S1'
  echo "$output" | grep -q '\[FAIL\] *S2'
}

@test "v1.2 target with missing spec entry exits 0 (S1 ok, not FAIL)" {
  run bash "$CHECK" --target-version 1.2 "$FIXTURES/eidolon-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *S1'
}

@test "v1.3 target with spec_file present passes S2" {
  run bash "$CHECK" "$FIXTURES/eidolon-v13-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'S2:spec-file'
}

@test "--target-version 1.3 explicit with no-specfile manifest fails S2" {
  run bash "$CHECK" --target-version 1.3 "$FIXTURES/eidolon-v13-no-specfile"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q 'S2:spec-file-missing'
}

# --- v1.4 canonical inventory gates (I1-I5) ---------------------------------- #

@test "eidolon-v14-conformant fixture exits 0 (I1-I5 all pass)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v14-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *I1'
  echo "$output" | grep -q '\[OK\] *I2'
  echo "$output" | grep -q '\[OK\] *I3'
  echo "$output" | grep -q '\[OK\] *I4'
  echo "$output" | grep -q '\[OK\] *I5'
}

@test "eidolon-v14-conformant I2 records agent-profile + spec" {
  run bash "$CHECK" "$FIXTURES/eidolon-v14-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'I2:two-file-pair'
  echo "$output" | grep -q 'agent-profile'
}

@test "eidolon-v14-non-whitelisted-file fixture exits 2 (I1 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v14-non-whitelisted-file"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *I1'
  echo "$output" | grep -q 'I1:inventory'
  echo "$output" | grep -q 'CLAUDE.md'
}

@test "eidolon-v14-missing-agent-profile fixture exits 2 (I2 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v14-missing-agent-profile"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *I2'
  echo "$output" | grep -q 'I2:two-file-pair'
  echo "$output" | grep -q "agent-profile"
}

@test "eidolon-v14-missing-ecl-version fixture exits 2 (I3 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v14-missing-ecl-version"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *I3'
  echo "$output" | grep -q 'I3:ecl-version'
}

@test "v1.3 target with agent-profile role exits 0 (I2 warn-only at v1.3)" {
  # At EIIS_VERSION 1.3 the missing agent-profile is warn-only, not MUST-fail.
  run bash "$CHECK" --target-version 1.3 "$FIXTURES/eidolon-v14-missing-agent-profile"
  # The fixture exits 2 due to other pre-existing failures (F-series from minimal
  # install.sh); we verify I2 does NOT produce a [FAIL] at v1.3.
  ! echo "$output" | grep -q '\[FAIL\] *I2'
}

@test "--target-version 1.4 explicit with conformant fixture exits 0" {
  run bash "$CHECK" --target-version 1.4 "$FIXTURES/eidolon-v14-conformant"
  [ "$status" -eq 0 ]
}

# --- v1.5 hook role gates (I6) --------------------------------------------- #

@test "eidolon-v15-conformant fixture exits 0 (I1-I6 all pass)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v15-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\[OK\] *I1'
  echo "$output" | grep -q '\[OK\] *I2'
  echo "$output" | grep -q '\[OK\] *I3'
  echo "$output" | grep -q '\[OK\] *I4'
  echo "$output" | grep -q '\[OK\] *I5'
  echo "$output" | grep -q '\[OK\] *I6'
}

@test "eidolon-v15-conformant I6 records hook-consistency ok" {
  run bash "$CHECK" "$FIXTURES/eidolon-v15-conformant"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'I6:hook-consistency'
  echo "$output" | grep -q 'hook_event'
}

@test "eidolon-v15-missing-hook-event fixture exits 2 (I6 fails)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v15-missing-hook-event"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *I6'
  echo "$output" | grep -q 'I6:hook-consistency'
  echo "$output" | grep -q 'missing hook_event'
}

@test "eidolon-v15-undeclared-hook-file fixture exits 2 (I6 fails, I1 still passes)" {
  run bash "$CHECK" "$FIXTURES/eidolon-v15-undeclared-hook-file"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *I6'
  echo "$output" | grep -q 'I6:hook-consistency'
  echo "$output" | grep -q 'hooks/rogue.sh'
  # I1 (inventory whitelist) still passes: hooks/*.sh is whitelisted at v1.5;
  # I6 (manifest sweep-symmetry) is the check that catches the stowaway file.
  echo "$output" | grep -q 'I1:inventory — all files in target/ are in the'
}

@test "eidolon-v15-undeclared-hook-file at --target-version 1.4 fails I1 (hooks/ not whitelisted pre-v1.5)" {
  run bash "$CHECK" --target-version 1.4 "$FIXTURES/eidolon-v15-undeclared-hook-file"
  echo "$output" | grep -q '\[FAIL\] *I1'
  echo "$output" | grep -q 'hooks/rogue.sh'
}

@test "v1.4 target with missing hook_event does not I6-fail (warn-only regression)" {
  # At EIIS_VERSION 1.4 the hook_event MUST is not yet in force — I6 warns,
  # it does not [FAIL]. (Other pre-existing gates on this minimal-install.sh
  # fixture may still fail; we only assert I6's own grade here.)
  run bash "$CHECK" --target-version 1.4 "$FIXTURES/eidolon-v15-missing-hook-event"
  ! echo "$output" | grep -q '\[FAIL\] *I6'
  echo "$output" | grep -q '\[WARN\] *I6'
}

@test "--target-version 1.5 explicit with conformant fixture exits 0" {
  run bash "$CHECK" --target-version 1.5 "$FIXTURES/eidolon-v15-conformant"
  [ "$status" -eq 0 ]
}

# --- v3 self-contained layout --------------------------------------------- #

@test "eidolon-v30-conformant fixture passes every v3 gate" {
  run bash "$CHECK" "$FIXTURES/eidolon-v30-conformant"
  [ "$status" -eq 0 ]
  for gate in V3-P1 V3-M1 V3-S1 V3-R1 V3-H1 V3-A1 V3-I1 V3-I2; do
    echo "$output" | grep -q "\[OK\] *${gate}"
  done
}

@test "v3 rejects legacy agent.md in the package" {
  run bash "$CHECK" "$FIXTURES/eidolon-v30-duplicated"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *V3-P1'
}

@test "v3 schema rejects malformed skill discovery and escaping resources" {
  run bash "$CHECK" "$FIXTURES/eidolon-v30-bad-layout"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[FAIL\] *V3-M1'
}
