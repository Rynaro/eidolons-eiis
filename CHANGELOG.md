# Changelog

All notable changes to the Eidolons Individual Install Standard (EIIS) will
be documented in this file. The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
document level.

## [Unreleased]

## [1.1.0] — 2026-04-25

### Added

- `spec/eiis-1.1.md` — additive minor release over v1.0. v1.0-conformant
  Eidolons remain conformant under v1.1 without modification.
- §4.5 — **Codex subagent contract**. Defines the per-Eidolon
  `.codex/agents/<name>.md` Markdown file with normative YAML frontmatter
  (`name` and `description` REQUIRED; `tools`, `model` OPTIONAL) and
  filename-namespacing as the collision-avoidance mechanism. Aligns with
  OpenAI's published Codex subagent format
  (<https://developers.openai.com/codex/subagents>).
- §4.1.0 — **`AGENTS.md` co-ownership clarification**. Root `AGENTS.md`
  is co-owned by the `copilot` and `codex` hosts. Per the cross-vendor
  `agents.md` convention and OpenAI's Codex documentation
  (<https://developers.openai.com/codex/guides/agents-md>), Codex reads
  `AGENTS.md` from the repo root; the marker convention from §4.1
  applies unchanged.
- §3.2 — `codex` added to the `hosts_wired` enum. Additive; v1.0-only
  manifests remain valid.
- `conformance/lib/checks-codex.sh` — new C-series checks (C0–C5)
  validating `.codex/agents/*.md` frontmatter under EIIS_VERSION 1.1+
  targets. Optional surface; absence is OK. C2 enforces slug shape;
  C3 enforces non-empty `description`; C5 warns on duplicate `name:`
  values across files.
- `conformance/check.sh` — recognises `1.1` (and `1.1.x`) as a known
  target version; runs §4.5 codex gates only when the target is v1.1+.
  v1.0 targets keep the original exit semantics (codex checks emit a
  skip note and contribute no failures).
- `conformance/tests/fixtures/eidolon-codex-conformant/` — new fixture;
  ships a valid `.codex/agents/conformant.md`.
- `conformance/tests/fixtures/eidolon-codex-bad-frontmatter/` — new
  fixture; missing `description:` exits 2 (C3 MUST violation).
- `conformance/tests/conformance.bats` — four new tests covering the
  codex addendum and backward compatibility (v1.0 fixtures still exit 0).
- `templates/eidolon-skeleton/.codex/agents/skeleton.md` — starter
  subagent file with valid v1.1 frontmatter.
- `templates/eidolon-skeleton/install.sh` — wires the `codex` slot:
  detection (`.codex/` strong signal; `AGENTS.md` alone), `--hosts all`
  expansion, validation enum, root-`AGENTS.md` writeback (regardless of
  `--shared-dispatch`, per §4.1.0), and `.codex/agents/<name>.md`
  emission via `write_per_host_dispatch`.

### Changed

- `EIIS_VERSION` (root) bumped from `1.0` to `1.1`.
- `SPEC.md` symlink repointed to `spec/eiis-1.1.md`.
- §4.2 host table — `codex` row promoted from "v1.1+" annotation to a
  first-class entry, cross-referencing §4.5.
- §4.3 vendor frontmatter pointers — `codex` row likewise promoted.
- Drift register cross-reference — D-2 (`codex` enum) marked resolved
  in v1.1.

### Backward compatibility

- v1.0-conformant Eidolons (those with `EIIS_VERSION 1.0`) pass v1.1
  conformance unchanged. The conformance checker skips §4.5 gates for
  v1.0 targets and emits a `[OK] C0` note instead.
- Codex support is OPTIONAL. Eidolons MAY ship `.codex/agents/<name>.md`
  but are not required to. Eidolons that do MUST satisfy §4.5.
- No new top-level files are required at the repo root. v1.1 is purely
  additive at the file-set level.

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

[Unreleased]: https://github.com/Rynaro/eidolons-eiis/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Rynaro/eidolons-eiis/releases/tag/v1.1.0
[1.0.0]: https://github.com/Rynaro/eidolons-eiis/releases/tag/v1.0.0
