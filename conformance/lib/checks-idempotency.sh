# shellcheck shell=bash
# EIIS §5 — Idempotency requirements. Sourced by check.sh.
#
# A full idempotency proof requires running install.sh twice in a
# sandbox and diffing outputs. That's expensive and side-effecting; we
# defer it to the per-Eidolon CI workflow at
# templates/github-actions-eidolon-ci.yml.
#
# Here we perform static heuristics:
#
#   - I1: install.sh contains an idempotency guard (re-install detection
#         keyed off install.manifest.json or a state file).
#   - I2: install.sh either uses upsert_eidolon_block (or equivalent
#         marker-aware helper) OR has no shared-dispatch writes.
#
# A third gate, I3 (re-run produces byte-identical output), is exercised
# via the bats fixture eidolon-not-idempotent and via the CI workflow.
#
# Public function: eiis_check_idempotency <repo-dir-absolute>

eiis_check_idempotency() {
  local dir="$1"
  local script="$dir/install.sh"

  if [ ! -f "$script" ]; then
    record "I0" "MUST" "fail" "install.sh missing — idempotency checks skipped"
    return
  fi

  # I1 — guarded re-install
  if grep -qE 'install\.manifest\.json' "$script"; then
    record "I1" "MUST" "ok" "install.sh references install.manifest.json (idempotency guard signal)"
  else
    record "I1" "MUST" "warn" "install.sh has no detectable idempotency guard" \
      "no reference to install.manifest.json; check.sh cannot prove --force re-run is byte-stable"
  fi

  # I2 — marker-aware shared-dispatch (covered structurally in checks-markers
  # K2/K3/K4; we surface a separate gate here for the §5 view).
  if grep -Eq '<!-- eidolon:|upsert_eidolon_block' "$script"; then
    record "I2" "MUST" "ok" "install.sh uses marker-aware shared-dispatch helpers"
  else
    if grep -Eq '(>>|>)[[:space:]]*"?(\./)?(CLAUDE\.md|AGENTS\.md|\.github/copilot-instructions\.md)' "$script"; then
      record "I2" "MUST" "fail" "install.sh writes to shared-dispatch files but is not marker-aware (re-run will append)"
    else
      record "I2" "MUST" "ok" "no shared-dispatch writes; per-host files use filename namespace"
    fi
  fi

  # I3 — installed_at is the only non-deterministic field (§3.5). We
  # check that the manifest write block is bracketed by a single
  # `installed_at` substitution and contains no other date/time
  # functions for required fields.
  local nondet_count
  nondet_count="$(grep -cE '\$\(date|`date|\$RANDOM' "$script" || true)"
  if [ "${nondet_count:-0}" -le 1 ]; then
    record "I3" "MUST" "ok" "install.sh has at most one non-deterministic substitution (installed_at)"
  else
    record "I3" "MUST" "warn" "install.sh has ${nondet_count} non-deterministic substitutions" \
      "verify only installed_at varies between runs"
  fi
}
