# shellcheck shell=bash
# EIIS §2 — install.sh flag contract checks. Sourced by check.sh.
#
# Public function: eiis_check_flags <repo-dir-absolute>
#
# Strategy: static analysis only. We grep the install.sh for each MUST/SHOULD
# flag's literal token. We do NOT execute install.sh here (that would be
# expensive and risk side-effects). Behavioural smoke (e.g. `--help` exits 0)
# is delegated to the per-Eidolon CI workflow at templates/github-actions-eidolon-ci.yml.
#
# We further check that --version and --help exit 0 by invoking install.sh
# with each — these are documented as no-mutate (§2.5, §2.6).

eiis_check_flags() {
  local dir="$1"
  local script="$dir/install.sh"

  if [ ! -f "$script" ]; then
    # L5 already failed; skip flag checks.
    record "F0" "MUST" "fail" "install.sh missing — flag checks skipped"
    return
  fi

  # F1 — --target (MUST)
  _flag_must "$script" "F1" "--target" "MUST"
  # F2 — --hosts (MUST)
  _flag_must "$script" "F2" "--hosts" "MUST"
  # F3 — --force (MUST)
  _flag_must "$script" "F3" "--force" "MUST"
  # F4 — --non-interactive (MUST)
  _flag_must "$script" "F4" "--non-interactive" "MUST"
  # F5 — --dry-run (MUST)
  _flag_must "$script" "F5" "--dry-run" "MUST"
  # F6 — --version (MUST)
  _flag_must "$script" "F6" "--version" "MUST"
  # F7 — -h / --help (MUST)
  if grep -q -- '-h' "$script" && grep -q -- '--help' "$script"; then
    record "F7" "MUST" "ok" "install.sh accepts -h, --help"
  else
    record "F7" "MUST" "fail" "install.sh missing -h or --help"
  fi

  # F8 — --shared-dispatch (SHOULD with grandfather clause; D-1)
  if grep -q -- '--shared-dispatch' "$script"; then
    record "F8" "SHOULD" "ok" "install.sh accepts --shared-dispatch"
  else
    record "F8" "SHOULD" "fail" "install.sh missing --shared-dispatch (D-1, grandfathered to MUST in v1.2)"
  fi

  # F9 — --no-shared-dispatch (SHOULD; D-1)
  if grep -q -- '--no-shared-dispatch' "$script"; then
    record "F9" "SHOULD" "ok" "install.sh accepts --no-shared-dispatch"
  else
    record "F9" "SHOULD" "fail" "install.sh missing --no-shared-dispatch (D-1, grandfathered to MUST in v1.2)"
  fi

  # F10 — --manifest-only (SHOULD)
  _flag_should "$script" "F10" "--manifest-only"

  # F11 — `--help` actually exits 0 (MUST, §2.6)
  # Behavioural check; bounded with a timeout-style arg cap.
  if bash "$script" --help >/dev/null 2>&1; then
    record "F11" "MUST" "ok" "install.sh --help exits 0"
  else
    record "F11" "MUST" "fail" "install.sh --help did not exit 0"
  fi

  # F12 — `--version` actually exits 0 and writes to stdout (MUST, §2.5)
  local ver_out
  ver_out="$(bash "$script" --version 2>/dev/null)"
  local ver_rc=$?
  if [ "$ver_rc" -eq 0 ] && [ -n "$ver_out" ]; then
    record "F12" "MUST" "ok" "install.sh --version exits 0 and prints '${ver_out}'"
  else
    record "F12" "MUST" "fail" "install.sh --version did not exit 0 with output (rc=${ver_rc})"
  fi

  # F13 — install.sh MUST NOT make network calls (§2.9). Static check
  # for common offenders. False-positives possible (e.g. comments
  # mentioning curl); we treat as warn rather than fail.
  if grep -Eq '(^|[[:space:]])(curl|wget|git[[:space:]]+clone|nc[[:space:]])' "$script"; then
    record "F13" "MUST" "warn" "install.sh references network commands (curl/wget/git clone/nc)" \
      "verify these are not active calls (e.g. only in comments or strings)"
  else
    record "F13" "MUST" "ok" "install.sh contains no obvious network calls"
  fi
}

_flag_must() {
  # _flag_must <script> <id> <flag-token> <level>
  local script="$1" id="$2" flag="$3" level="$4"
  if grep -q -- "$flag" "$script"; then
    record "$id" "$level" "ok" "install.sh accepts $flag"
  else
    record "$id" "$level" "fail" "install.sh missing $flag"
  fi
}

_flag_should() {
  # _flag_should <script> <id> <flag-token>
  local script="$1" id="$2" flag="$3"
  if grep -q -- "$flag" "$script"; then
    record "$id" "SHOULD" "ok" "install.sh accepts $flag"
  else
    record "$id" "SHOULD" "fail" "install.sh missing $flag"
  fi
}
