# Contributing to EIIS

EIIS is a versioned standard. Changes fall into four categories, each with
its own evolution path.

## Categories of change

| Change | SemVer impact | Process |
|---|---|---|
| Typo fix, clarification, link rot | PATCH (`1.0.0 → 1.0.1`) | Direct PR; no new spec file |
| Additive feature (new optional field, new host enum value, new SHOULD) | MINOR (`1.0.0 → 1.1.0`) | New `spec/eiis-X.Y.md` file; updates `SPEC.md` symlink |
| Breaking change to a MUST | MAJOR (`1.0.0 → 2.0.0`) | New `spec/eiis-X.0.md` file; migration guide; conformance checker grows new `--target-version` value |
| Drift promotion (warn → fail) | MINOR or MAJOR depending on the field | Pre-announced in §6 promotion timeline |

## How to propose a change

1. **Open an issue** describing the change, the affected drift (if any),
   and which Eidolons are impacted.
2. **Discuss** with the maintainers. Cross-repo coordination (e.g.
   patching the six shipped Eidolons) is part of the design.
3. **Open a PR** with:
   - Updated or new `spec/eiis-X.Y.md` (if the change is non-trivial).
   - Updated `schemas/` if the manifest contract changes.
   - Updated `conformance/lib/*.sh` to enforce the new rule.
   - Updated `conformance/tests/` fixtures and bats suite.
   - Updated `CHANGELOG.md`.
   - Updated `EIIS_VERSION` if the minor or major changed.
4. **CI must pass.** Both `conformance.yml` (bats suite) and
   `self-check.yml` (skeleton template self-test).

## Versioning rules

- `EIIS_VERSION` at repo root is the bare SemVer string of the latest
  stable spec (e.g. `1.0`). PATCH releases do not bump this.
- `SPEC.md` is always a symlink to the latest stable `spec/eiis-X.Y.md`.
- Old spec files stay in the tree forever — conformance is checkable
  against any historical version.

## Drift promotion process

The §6 promotion timeline in `spec/eiis-1.0.md` lists drifts D-3 and D-6
as warn-only until 2027-04-24. To promote them:

1. Verify every Eidolon listed in `IMPLEMENTORS.md` has the relevant fix
   tagged in their own repo.
2. Open a PR titled `feat: promote D-N from warn to fail in vX.Y`.
3. Update `conformance/lib/checks-*.sh` to flip the warn-only branch to
   fail.
4. Bump `EIIS_VERSION` (MINOR if additive, MAJOR if breaking).
5. Update `CHANGELOG.md`.

## Style

- Spec prose: RFC 8174 keywords in CAPS only when normative. Cite both
  RFC 2119 and RFC 8174 at the top of every spec file.
- Shell scripts: bash 3.2 compatible (macOS default). No bash 4+ features
  (no associative arrays, no `${var,,}`/`${var^^}`, no `readarray`/`mapfile`).
- shellcheck-clean (`-S error`) for everything in `conformance/` and
  `templates/eidolon-skeleton/install.sh`.
- No emojis in spec files or tooling output.

## Reporting bugs in the conformance checker

Open an issue with:

- The exact command that failed.
- The Eidolon repo at issue (path or URL + tag).
- Expected vs actual exit code and output.
- `bash --version` and OS.
