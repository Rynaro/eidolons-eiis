# Changelog

## [3.0.0] — 2026-08-17

- Replace duplicated agent and skill surfaces with one canonical installed tree.
- Introduce `PERSONA.md`, directory skills, colocated resources, and discovery-only adapters.
- Add strict v3 conformance gates while preserving the complete EIIS 1.x checker path.
- Extend the manifest schema with v3 contract, persona, resource, and adapter metadata.

All notable changes to the Eidolons Individual Install Standard (EIIS) will
be documented in this file. The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
document level.

## [Unreleased]

## [1.5.0] — 2026-07-02

### Added

- `spec/eiis-1.5.md` — additive minor release over v1.4. v1.0-, v1.1-,
  v1.2-, v1.3-, and v1.4-conformant Eidolons remain conformant under v1.5
  without modification. The new MUSTs bind only when an Eidolon declares
  `EIIS_VERSION = 1.5`. Closes the install-contract gap around host
  session/prompt hooks (e.g. a Claude Code `SessionStart` or
  `UserPromptSubmit` shim): previously these files had no home in EIIS, so
  they could not be inventory-tracked, swept on uninstall, or
  doctor-verified against a manifest.
- **New `files_written[].role` value `"hook"` (§3.3).** Tags a host-hook
  shim file written under `<target>/hooks/`.
- **§3.7.2 — `hook_event` field (v1.5+).** Every `files_written[]` entry
  with `role: "hook"` MUST carry a `hook_event`: a closed four-member enum
  (`session-start`, `prompt-submit`, `pre-tool`, `stop`). Schema-optional
  for every role; conformance-required for `role: "hook"`. Compliance
  grade: MUST-fail at `EIIS_VERSION ≥ 1.5`; warn-only at `≤ 1.4`.
- **§1.9.7–§1.9.9 — `hooks/` inventory whitelist (amended §1.9, v1.5+).**
  `<target>/hooks/<name>.sh` joins the §1.9.1 whitelist table: flat layout
  only (no subdirectories), `.sh` extension, role `hook`. A v1.4-declared
  Eidolon shipping a `hooks/` directory still fails `I1` — the path is not
  whitelisted before v1.5.
- **§4.7 — Hook wiring conventions (v1.5+).** Splits the hook **shim file**
  (tracked as `files_written[]` role `hook`) from the **host-config
  registration** that wires the shim into the host (tracked as
  `files_written[]` role `dispatch`, under the existing host-wiring/marker
  rules — no new manifest surface for the registration itself). Explicitly
  states the security model is unchanged: per-Eidolon installers still
  write only to the consumer project's working directory; hooks introduce
  no new write surface (§4.7.4). Hook execution semantics (stdin/stdout
  contract, exit codes, host hook-payload JSON schema) are declared a
  non-goal (§4.7.5, §7) — EIIS governs presence/tracking/sweep only.
- **§6.X.7 — Hook sweep clarification (v1.5+).** States explicitly that the
  §6.X manifest-driven cleanup sweep removes `role: "hook"` files exactly
  as it removes files of any other role. Declarative — the generic sweep
  already covers hook files by construction.
- **Schema additions** (`schemas/install.manifest.v1.json`):
  - `role` enum gains `"hook"`.
  - `files_written[]` items gain optional field `hook_event` (closed enum:
    `session-start`, `prompt-submit`, `pre-tool`, `stop`).
  - No schema version bump (`v1` retained) — additive-optional, the same
    precedent v1.4 set for `agent-profile`/`ecl-version` and
    `canonical_inventory_strict`.
- **Conformance checker additions** (`conformance/lib/checks-inventory.sh`):
  - `I6` — every `role: "hook"` entry has a valid `hook_event`; every file
    under `<target>/hooks/` is manifest-declared with `role: "hook"` (sweep
    symmetry). MUST-fail for `EIIS_VERSION ≥ 1.5`; warn-only for `≤ 1.4`.
  - `I1`'s §1.9.1 whitelist walk gains a `hooks/*.sh` branch, active only
    when the target declares `EIIS_VERSION ≥ 1.5`.
  - `checks-manifest.sh`'s `M13` role-enum check is updated to accept
    `"hook"` without MUST-failing (same treatment v1.4 gave
    `agent-profile`/`ecl-version`).
- **New test fixtures**: `eidolon-v15-conformant`,
  `eidolon-v15-missing-hook-event`, `eidolon-v15-undeclared-hook-file`.
  Seven new bats tests (35–41), all green — including an explicit
  sub-1.5 warn-only regression test and an I1-vs-I6 isolation test
  (undeclared hook file passes the whitelist gate but fails the
  manifest-sweep-symmetry gate).

### Compatibility

v1.0/v1.1/v1.2/v1.3/v1.4 Eidolons remain conformant under v1.5. The new
MUST (`I6`) is gated on `EIIS_VERSION ≥ 1.5`; warn-only at `≤ 1.4`. The
hard-fail promotion target date (§6.4) is **unchanged at 2027-04-24** — it
is a single global clock shared by every warn-only field since v1.0; v1.5
adds new rows to the existing table, it does not open a new promotion
window or introduce a per-version date.

## [1.4.0] — 2026-05-26

### Added

- `spec/eiis-1.4.md` — additive minor release over v1.3. v1.0-, v1.1-, v1.2-,
  and v1.3-conformant Eidolons remain conformant under v1.4 without
  modification. The new MUSTs bind only when an Eidolon declares
  `EIIS_VERSION = 1.4`.
- **§1.9 — Canonical install-target inventory whitelist (v1.4+).** Only files
  listed in the §1.9.1 table may appear under `<target>/`. Any other path is
  a v1.4 conformance violation. Whitelist: `agent.md`, `SPEC.md`,
  `install.manifest.json`, `ECL_VERSION` (conditional), `skills/<skill>.md`,
  `templates/<artifact>.md`, `schemas/<schema>.json`. Compliance grade:
  MUST-fail at `EIIS_VERSION ≥ 1.4`; warn-only at `≤ 1.3`.
- **§1.8.6 — Two-file canonical pair (`agent-profile` role).** `agent.md`
  MUST appear in `files_written[]` with `role: "agent-profile"` and basename
  `agent.md`. Exactly one per install. Compliance grade: MUST-fail at
  `EIIS_VERSION ≥ 1.4`.
- **§3.7.1 — `ECL_VERSION` install-target copy (v1.4+).** When the source
  repo declares `ECL_VERSION`, the installer MUST copy it to
  `<target>/ECL_VERSION` and record it in `files_written[]` with
  `role: "ecl-version"`. Compliance grade: MUST-fail at `EIIS_VERSION ≥ 1.4`.
- **§4.2.3–§4.2.5 — Host-vendor agent file body contract (v1.4+).** The
  claude-code dispatch file MUST reference both `agent.md` (P0) and `SPEC.md`
  (deep spec); MUST NOT reference legacy spec filenames or subdir-skill paths.
  §4.2.6 defines the canonical heredoc template. Compliance grade: MUST-fail
  at `EIIS_VERSION ≥ 1.4`.
- **§6.X — Install-target cleanup obligation (v1.4+).** After a successful
  install the installer MUST sweep any file under `<target>/` not in the
  current `files_written[]` set. Manifest-driven; replaces ad-hoc per-Eidolon
  `cleanup_legacy_v1_2` lists. Reference implementation in Appendix A.
- **§6.Y — `agent.md` content consistency (v1.4+).** Every `skills/<skill>.md`
  reference inside `<target>/agent.md` MUST resolve to a `files_written[]`
  entry. MUST NOT reference subdir-layout or legacy-spec filenames.
- **Schema additions** (`schemas/install.manifest.v1.json`):
  - `role` enum gains `"agent-profile"` and `"ecl-version"`.
  - New optional top-level field `canonical_inventory_strict` (boolean).
- **Conformance checker additions** (`conformance/lib/checks-inventory.sh`):
  - `I1` — Inventory whitelist (MUST-fail ≥ 1.4; warn-only ≤ 1.3).
  - `I2` — Two-file canonical pair: `agent-profile` + `spec` each exactly
    once (MUST-fail ≥ 1.4).
  - `I3` — `ECL_VERSION` target copy when source declares it (MUST-fail ≥ 1.4).
  - `I4` — Host-vendor refs: `.claude/agents/<n>.md` references both `agent.md`
    and `SPEC.md`; no legacy names (MUST-fail ≥ 1.4).
  - `I5` — `agent.md` skill-path consistency (MUST-fail ≥ 1.4).
- **Skeleton template** (`templates/eidolon-skeleton/`): updated to v1.4
  patterns — `agent-profile` role, `canonical_inventory_sweep()`, conditional
  ECL_VERSION copy, §4.2.6 claude-code heredoc template.
- **New test fixtures**: `eidolon-v14-conformant`, `eidolon-v14-non-whitelisted-file`,
  `eidolon-v14-missing-agent-profile`, `eidolon-v14-missing-ecl-version`.
  Seven new bats tests (28–34), all green.

### §1.7 numbering note

v1.3 §1.7 ("MUST NOT collide with EIIS-reserved names") is preserved
unchanged. The new inventory-whitelist clause is placed at **§1.9** (not §1.7
as the draft used for readability). This follows OQ-A default guidance in the
v1.4 spec. The choice is documented at the top of `spec/eiis-1.4.md`.

### Compatibility

v1.0/v1.1/v1.2/v1.3 Eidolons remain conformant under v1.4. All new MUSTs
(`I1`–`I5`) are gated on `EIIS_VERSION ≥ 1.4`; warn-only at `≤ 1.3`. The
`M13` role-enum check in `checks-manifest.sh` is updated to accept the new
`"agent-profile"` and `"ecl-version"` roles without MUST-failing.

## [1.3.0] — 2026-05-25

### Added

- `spec/eiis-1.3.md` — additive minor release over v1.2. v1.0-, v1.1-, and
  v1.2-conformant Eidolons remain conformant under v1.3 without modification.
- §1.8 — **Canonical full-spec filename (v1.3+)**. Eidolons declaring
  `EIIS_VERSION = 1.3` MUST write their full methodology spec at exactly
  `<target>/SPEC.md`. A `files_written[]` entry with `role: "spec"` whose
  basename is not `SPEC.md` is a v1.3 conformance violation (§1.8.2). Exactly
  one such entry per install is required (§1.8.3). Warn-only through
  2027-04-24 for Eidolons declaring `EIIS_VERSION ≤ 1.2` (§1.8.5).
- §4.2.4 — **Skills dual-write (v1.3+)**. An Eidolon that ships skill files
  MUST write each skill at both:
  - `<target>/skills/<skill>.md` — flat source-of-truth (host-independent).
  - `.claude/skills/<eidolon>-<skill>/SKILL.md` — Claude Code vendor copy
    (only when `claude-code` is in `--hosts`).
  Both files MUST be byte-identical at write time (§4.2.4.2). The v1.2
  subdir layout (`<skill>/SKILL.md`) is deprecated for v1.3+ Eidolons
  (§4.2.4.3). Warn-only for `EIIS_VERSION ≤ 1.2` (§4.2.4.6).
- §3.7 — Two new optional manifest fields (schema-optional;
  conformance-required at `EIIS_VERSION ≥ 1.3`):
  - `spec_file` — canonical full-spec path pointer
    (`^\.eidolons/[a-z][a-z0-9-]*/SPEC\.md$`).
  - `skills[]` — per-skill dual-write record (name, source_path,
    source_sha256, optional vendor_path / vendor_sha256).
- `schemas/install.manifest.v1.json` — three additive schema additions:
  - `spec_file` optional string field with pattern validation.
  - `skills` optional array field with per-entry shape validation.
  - `ecl_version_emitted` optional string field (previously documented in
    §3.7 but missing from the schema; backfilled from v1.2).
- `conformance/lib/checks-spec-skills.sh` — new S- and K-series checks:
  - **S1** — `role: "spec"` entry basename is `SPEC.md` (MUST-fail ≥ 1.3).
  - **S2** — `spec_file` field present and pattern-valid (MUST-fail ≥ 1.3).
  - **K1** — `skills[]` `source_path` uses flat layout (MUST-fail ≥ 1.3).
  - **K2** — `vendor_sha256` equals `source_sha256` when present
    (MUST-fail ≥ 1.3).
  - **K3** — `vendor_path` present when `claude-code` in `hosts_wired` and
    skills exist (WARN, all versions).
- `conformance/tests/fixtures/eidolon-v13-conformant/` — new fixture with
  `spec_file`, `skills[]`, and `role: "spec"` path ending in `SPEC.md`.
  Exits 0 on `check.sh`.
- `conformance/tests/fixtures/eidolon-v13-no-specfile/` — new fixture at
  `EIIS_VERSION = 1.3` with no `spec_file` and no `role: "spec"` entry.
  Exits 2 on `check.sh` (S1 + S2 MUST-fail).
- `conformance/tests/conformance.bats` — 5 new tests covering v1.3 gates
  and backward compatibility.
- Appendix A in `spec/eiis-1.3.md` — non-normative `wire_skill` reference
  implementation (bash 3.2 compatible copy-paste snippet for Eidolon authors).
- Appendix B in `spec/eiis-1.3.md` — changes-from-v1.2 summary table.
- `templates/eidolon-skeleton/SPEC.md` — placeholder canonical spec file.
- `templates/eidolon-skeleton/install.sh` — updated with `wire_skill`
  helper and SPEC.md copy pattern.

### Changed

- §4.2.3 (amended) — `.claude/skills/` write promoted from **MAY** to **MUST**
  for v1.3-conformant Eidolons when `claude-code` is wired. Cursor/Codex/
  OpenCode vendor-copy paths remain **MAY** (out of scope for v1.3).
- `conformance/check.sh` — recognises `1.3` (and `1.3.x`) as a known target
  version; wires `eiis_check_spec_skills` for S- and K-series gate execution.
- `EIIS_VERSION` (root) bumped from `1.2` to `1.3`.
- `SPEC.md` symlink repointed to `spec/eiis-1.3.md`.
- `templates/eidolon-skeleton/EIIS_VERSION` bumped from `1.1` to `1.3`.

### Compatibility

- v1.0-, v1.1-, and v1.2-conformant Eidolons pass v1.3 conformance unchanged.
  The new MUSTs (§1.8 and §4.2.4) bind only when `EIIS_VERSION ≥ 1.3`. No
  existing Eidolon that has not opted in by bumping its `EIIS_VERSION` to `1.3`
  is affected. Migration is additive and per-repo.

## [1.2.0] — 2026-05-08

### Added

- `spec/eiis-1.2.md` — additive minor release over v1.1. v1.0- and
  v1.1-conformant Eidolons remain conformant under v1.2 without modification.
- §4.6 — **ECL composition (v1.2+)**. Acknowledges the Eidolons Communication
  Layer (`Rynaro/eidolons-ecl` v1.0.0, published 2026-05-07) as a composable
  sibling standard. ECL governs wire-format and hand-off contracts for runtime
  inter-Eidolon communication; EIIS governs the install contract. They compose
  but do not overlap.
  - §4.6.1 — An Eidolon repo **MAY** contain a top-level `ECL_VERSION` file
    matching `^[0-9]+\.[0-9]+(\.[0-9]+)?$`, declaring the ECL spec version
    it targets when emitting inter-Eidolon artefacts.
  - §4.6.2 — If `ECL_VERSION` is present, an Eidolon that emits ECL envelopes
    MUST satisfy the corresponding ECL spec version. (ECL conformance is
    verified by the ECL checker, not EIIS.)
  - §4.6.3 — An Eidolon SHALL NOT emit ECL envelopes without declaring
    `ECL_VERSION`.
  - §4.6.4 — `install.manifest.json` MAY include an `ecl_version_emitted`
    string field; if present it MUST match `ECL_VERSION`.
  - §4.6.5 — Conformance checker adds warn-only E0 (ECL_VERSION format) and
    E1 (ecl_version_emitted ↔ ECL_VERSION match) gates for v1.2+ targets.
- `conformance/lib/checks-ecl.sh` — new E-series checks (E0–E1) validating
  `ECL_VERSION` format and manifest consistency under EIIS_VERSION 1.2+
  targets. Both checks are warn-only; absence of `ECL_VERSION` is OK and
  produces no output.
- §3.7 — `ecl_version_emitted` added as an OPTIONAL manifest field.
- §6.2.1 — Explicit backward-compatibility paragraph for v1.0/v1.1/v1.2.
- §6.3 — E0 and E1 added to the promotion timeline table.
- §7 — Non-goals bullet: EIIS does not define ECL semantics.
- Citation 10 — ECL v1.0 at `Rynaro/eidolons-ecl`.
- `ECL_VERSION` added to the MAY-contain table in §1.

### Changed

- `EIIS_VERSION` (root) bumped from `1.1` to `1.2`.
- `SPEC.md` symlink repointed to `spec/eiis-1.2.md`.

### Backward compatibility

- v1.0- and v1.1-conformant Eidolons pass v1.2 conformance unchanged. The
  ECL composition surface (§4.6) is entirely optional. Eidolons that emit no
  ECL artefacts remain fully conformant with no modification required.
- No new top-level files are required at the repo root. v1.2 is purely
  additive at the file-set level. `ECL_VERSION` is an opt-in file.
- Eidolons MAY add `ECL_VERSION` and MAY upgrade their
  `install.manifest.json` to include `ecl_version_emitted` independently,
  at any time, without a coordinated EIIS version bump.

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

[Unreleased]: https://github.com/Rynaro/eidolons-eiis/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/Rynaro/eidolons-eiis/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Rynaro/eidolons-eiis/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Rynaro/eidolons-eiis/releases/tag/v1.1.0
[1.0.0]: https://github.com/Rynaro/eidolons-eiis/releases/tag/v1.0.0
