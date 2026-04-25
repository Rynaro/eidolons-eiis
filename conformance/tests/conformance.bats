#!/usr/bin/env bats
# EIIS conformance checker — self-test suite.

setup() {
  EIIS_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  CHECK="$EIIS_ROOT/conformance/check.sh"
  FIXTURES="$EIIS_ROOT/conformance/tests/fixtures"
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
