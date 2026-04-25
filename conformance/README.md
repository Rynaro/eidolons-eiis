# conformance/

The standalone EIIS conformance checker. Bash 3.2 compatible. Hard
dependencies: `bash`, `jq`, POSIX coreutils. Optional: `ajv` or
`python3 -m jsonschema` for full JSON Schema validation of `install.manifest.json`.

## Usage

```bash
bash check.sh <eidolon-repo-dir> [options]
```

### Options

| Flag | Effect |
|---|---|
| `--level=MUST` | Suppress passing SHOULD lines from the human report (failures and warnings always print). |
| `--json` | Emit a machine-readable JSON report instead of the human format. |
| `--target-version 1.0` | Run gates for a specific EIIS version. Default: read `<repo>/EIIS_VERSION`; fall back to `1.0`. |
| `-h`, `--help` | Print help and exit 0. |
| `--version` | Print the checker's version and exit 0. |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Passes all MUSTs at the declared `EIIS_VERSION`. |
| `1` | Generic failure (missing dir, unreadable files, bad usage). |
| `2` | Fails one or more MUSTs. |
| `3` | Passes MUSTs but fails one or more SHOULDs (advisory; non-fatal in most CI). |
| `4` | Passes MUSTs but emits warn-only output for grandfathered drifts (D-3, D-6 within their warn-only window). CI MAY treat as success. |

## Gate ID scheme

| Prefix | Section | Topic |
|---|---|---|
| `L<n>` | §1 | Layout (file presence, EIIS_VERSION format) |
| `F<n>` | §2 | Flags (install.sh CLI contract) |
| `M<n>` | §3 | Manifest (install.manifest.json schema) |
| `K<n>` | §4 | Key (marker convention; "K" not "M" because M is taken) |
| `I<n>` | §5 | Idempotency (re-run behaviour) |

## Scope and limitations

The checker is **static** — it inspects the Eidolon repo's files and
optionally invokes `install.sh --help` and `install.sh --version` (both
of which §2.5 / §2.6 mandate as no-mutate operations). It does NOT
actually run a full install in a sandbox. Behavioural checks
(idempotency byte-equality, marker upsert correctness on real targets)
are delegated to the per-Eidolon CI workflow at
[`../templates/github-actions-eidolon-ci.yml`](../templates/github-actions-eidolon-ci.yml).

## Wiring into your Eidolon's CI

Drop [`templates/github-actions-eidolon-ci.yml`](../templates/github-actions-eidolon-ci.yml)
into your `.github/workflows/` and adjust the EIIS version pin. The
workflow:

1. Clones EIIS at the pinned tag.
2. Runs `bash conformance/check.sh .` against your repo.
3. Asserts exit code is 0 or 4 (MUSTs pass, warnings tolerated).

## Library structure

```
conformance/
├── check.sh                    # Entry point
├── lib/
│   ├── checks-layout.sh        # §1 (L<n> gates)
│   ├── checks-flags.sh         # §2 (F<n> gates)
│   ├── checks-manifest.sh      # §3 (M<n> gates)
│   ├── checks-markers.sh       # §4 (K<n> gates)
│   └── checks-idempotency.sh   # §5 (I<n> gates)
└── tests/
    ├── conformance.bats        # Self-test against fixtures
    └── fixtures/               # Hand-built test inputs
```

Each `lib/checks-*.sh` exposes one `eiis_check_<area>` function that
takes the absolute repo dir as its single argument and records results
via the parent's `record` helper.

## Running the self-test

```bash
bats conformance/tests/conformance.bats
```

Fixtures:

- `eidolon-conformant/` — passes every MUST gate.
- `eidolon-missing-file/` — missing `agent.md` (L1 fails).
- `eidolon-bad-manifest/` — manifest missing `hosts_wired` (M7 fails).
- `eidolon-no-markers/` — installer writes to `CLAUDE.md` without
  markers (K2 fails).
- `eidolon-not-idempotent/` — installer writes the same file twice
  with no idempotency guard (I1 fails).
