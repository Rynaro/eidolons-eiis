# Changelog

All notable changes to the Eidolons Individual Install Standard (EIIS) will
be documented in this file. The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
document level.

## [Unreleased]

## [1.0.0] — 2026-04-24

### Added

- First stable release of the Eidolons Individual Install Standard (EIIS).
- `spec/eiis-1.0.md` — normative spec with RFC 8174 (BCP 14) keywords,
  seven numbered sections (§1–§7).
- `SPEC.md` — symlink to `spec/eiis-1.0.md` (latest stable pointer).
- `EIIS_VERSION` — root file declaring the EIIS minor this repo targets.
- `schemas/install.manifest.v1.json` — JSON Schema (draft-2020-12) for
  the `install.manifest.json` artefact.
- `schemas/install.manifest.draft.md` — field-by-field rationale.
- `conformance/check.sh` — standalone bash 3.2-compatible conformance
  checker.
- `conformance/lib/checks-{layout,flags,manifest,markers,idempotency}.sh`
  — modular check suites.
- `conformance/tests/conformance.bats` plus five fixtures
  (`eidolon-conformant`, `eidolon-missing-file`, `eidolon-bad-manifest`,
  `eidolon-no-markers`, `eidolon-not-idempotent`).
- `templates/eidolon-skeleton/` — copy-paste starter that passes
  conformance out of the box.
- `templates/github-actions-eidolon-ci.yml` — reusable CI workflow.
- `examples/manifest-conformant.json` — worked example of a valid
  `install.manifest.json`.
- `IMPLEMENTORS.md` — list of known-conformant Eidolons.
- `CONTRIBUTING.md`, `docs/design-rationale.md`,
  `docs/relationship-to-nexus.md`.
- `.github/workflows/conformance.yml`, `self-check.yml`, `release.yml`.

### Drift register (codified)

- **D-1** — `--shared-dispatch` flag: SHOULD in v1.0; promoted to MUST in
  v1.2 (target date 2027-04-24).
- **D-3** — `files_written` populated: MUST with warn-only enforcement in
  v1.0; promoted to MUST-fail in v1.2.
- **D-4** — Marker convention in shared-dispatch writes: MUST, fail from
  v1.0.
- **D-5** — Installer version source-of-truth: codified as-is; meta-installer
  override permitted; deprecated in v2.0.
- **D-6** — `EIIS_VERSION` file: MUST with warn-only enforcement in v1.0;
  promoted to MUST-fail in v1.2.
- **D-7** — Required file set expanded beyond the legacy five-file check;
  conformance checker validates the full set.

### Resolved open questions

- **Q.1** — `EIIS_VERSION` lives at repo root (not `agent.md` frontmatter).
- **Q.3** — Cache invalidation deferred to a future `eidolons doctor`
  follow-up in the nexus repo.
- **Q.6** — `--strict` mode deferred to v1.1.
- **Q.7** — License is Apache-2.0 (matches the nexus and every shipped
  Eidolon).
- **Q.8** — Normative keywords use RFC 8174 (BCP 14); both RFC 2119 and
  RFC 8174 are cited.

[Unreleased]: https://github.com/Rynaro/eidolons-eiis/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Rynaro/eidolons-eiis/releases/tag/v1.0.0
