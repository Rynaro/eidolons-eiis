# EIIS — Eidolons Individual Install Standard

**Version:** 1.4
**Status:** Stable
**Published:** 2026-05-26
**Editors:** Rynaro and the Eidolons contributors
**License:** Apache-2.0

<!-- Note to editors: The draft spec used §1.7 throughout for the canonical
install-target inventory whitelist clause. In v1.3, §1.7 already contains the
"MUST NOT collide with EIIS-reserved names" rule. Per OQ-A the resolution is
to place the new clause at §1.9, preserving the v1.3 §1.7 numbering unchanged.
All I-series conformance gate identifiers are unaffected. -->

## Normative keywords

The keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**,
**SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in
this document are to be interpreted as described in
[BCP 14](https://www.rfc-editor.org/rfc/rfc8174)
([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119),
[RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)) when, and only when,
they appear in all capitals, as shown here.

## Status of this document

This is EIIS v1.4, an additive minor release over v1.3. v1.4 introduces six
normative changes for Eidolons that declare `EIIS_VERSION = 1.4`:

- **§1.9 — Canonical install-target inventory whitelist**: only files listed in
  the §1.9.1 table may appear under `<target>/`. Any other path is a v1.4
  conformance violation.

- **§1.8.6 — Two-file canonical pair**: `agent.md` MUST also appear in
  `files_written[]` with `role: "agent-profile"`. Every v1.4-conformant
  install emits exactly one `agent-profile` and exactly one `spec`.

- **§3.7.1 — `ECL_VERSION` install-target copy**: when a source repo declares
  `ECL_VERSION`, the installer MUST copy it to `<target>/ECL_VERSION` and
  record it in `files_written[]` with `role: "ecl-version"`.

- **§4.2.3–§4.2.5 — Host-vendor agent file body contract**: the claude-code
  dispatch file MUST reference both `agent.md` and `SPEC.md`; MUST NOT
  reference legacy spec filenames or subdir-skill paths.

- **§6.X — Install-target cleanup obligation**: after a successful install the
  installer MUST sweep any file under `<target>/` not in the current
  `files_written[]` set.

- **§6.Y — `agent.md` content consistency**: every `skills/<skill>.md`
  reference inside `<target>/agent.md` MUST resolve to a `files_written[]`
  entry.

v1.0-, v1.1-, v1.2-, and v1.3-conformant Eidolons remain conformant under
v1.4 without modification. The new MUSTs bind **only** when an Eidolon
declares `EIIS_VERSION = 1.4` or later, mirroring the backward-compat pattern
used in v1.1 (Codex addendum), v1.2 (ECL composition), and v1.3 (canonical
SPEC.md + skills dual-write). See [§6](#6--versioning--compatibility).

## Table of contents

- [§1 — Repo Layout](#1--repo-layout) (v1.0 baseline; §1.7, §1.8 from v1.3)
- [§1.8 — Canonical full-spec filename (amended v1.4)](#18--canonical-full-spec-filename-amended-v14)
- [§1.9 — Canonical install-target inventory whitelist (v1.4+)](#19--canonical-install-target-inventory-whitelist-v14)
- [§2 — `install.sh` flag contract](#2--installsh-flag-contract)
- [§3 — `install.manifest.json` schema](#3--installmanifestjson-schema)
- [§3.7.1 — `ECL_VERSION` install-target copy (v1.4+)](#371--ecl_version-install-target-copy-v14)
- [§4 — Host wiring conventions](#4--host-wiring-conventions)
- [§4.2 — Per-host dispatch files (amended v1.4)](#42--per-host-dispatch-files-amended-v14)
- [§5 — Idempotency requirements](#5--idempotency-requirements)
- [§6 — Versioning & compatibility](#6--versioning--compatibility)
- [§6.X — Install-target cleanup obligation (v1.4+)](#6x--install-target-cleanup-obligation-v14)
- [§6.Y — `agent.md` content consistency (v1.4+)](#6y--agentmd-content-consistency-v14)
- [§7 — Non-goals](#7--non-goals)
- [Citations](#citations)
- [Appendix A — `canonical_inventory_sweep` reference implementation](#appendix-a--canonical_inventory_sweep-reference-implementation)
- [Appendix B — Changes from v1.3](#appendix-b--changes-from-v13)

---

## §1 — Repo Layout

*(Unchanged from v1.3. Reproduced here for completeness.)*

A conformant Eidolon repository **MUST** contain at minimum, all at the
repository root:

| Path | Purpose | Stability |
|---|---|---|
| `agent.md` | Always-loaded entry-point document. SHOULD fit within an estimated 1000-token budget. | [Stable] |
| `AGENTS.md` | Vendor-neutral methodology summary. | [Stable] |
| `CLAUDE.md` | Claude Code surface document. | [Stable] |
| `README.md` | Human-readable repo introduction. | [Stable] |
| `install.sh` | Executable installer script (`bash`, with the executable bit set). | [Stable] |
| `EIIS_VERSION` | Single-line file containing a bare SemVer string declaring which EIIS minor the repo targets (e.g. `1.4`). | [Stable] |

§1.1 — **MUST**: each of the six paths above exists at the repository root.

§1.2 — **MUST**: `install.sh` is executable (`chmod +x install.sh` or
runnable via `bash install.sh`).

§1.3 — **MUST**: `EIIS_VERSION` contains exactly one line matching the
regular expression `^[0-9]+\.[0-9]+(\.[0-9]+)?$`. Trailing newline permitted.
The first two components (MAJOR and MINOR) declare the spec version this repo
targets.

§1.4 — **SHOULD**: a `CHANGELOG.md` in [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/) format.

§1.5 — **SHOULD**: a vendored copy of EIIS's manifest schema at
`schemas/install.manifest.v1.json` so installers can self-validate.

A conformant Eidolon repository **MAY** contain:

| Path | Purpose |
|---|---|
| `skills/<skill>.md` | Flat per-file skill source-of-truth (v1.3+ recommended layout). |
| `skills/<phase>/SKILL.md` | Legacy subdir skill layout (v1.2 and earlier; deprecated in v1.3). |
| `templates/<artifact>.md` | Output skeletons. |
| `evals/` | Canary missions or scenario tests. |
| `LICENSE` | Per-repo licence (RECOMMENDED). |
| `ECL_VERSION` | Single-line file declaring the ECL spec version this repo targets (see [§4.6](#46--ecl-composition-v12)). |

§1.6 — **MAY**: any additional Eidolon-specific files. EIIS does not
prohibit extension at the source-repo level.

§1.7 — **MUST NOT**: introduce paths whose names collide with EIIS-reserved
names listed in the table above with semantics that differ from this section.
*(Unchanged from v1.3.)*

---

## §1.8 — Canonical full-spec filename (amended v1.4)

This section is **normative**. §1.8.1–§1.8.5 are unchanged from v1.3.
§1.8.6–§1.8.7 are new in v1.4.

§1.8.1 — **MUST**: an Eidolon's installer writes its full methodology spec at
exactly one path under the install target:

```
<target>/SPEC.md
```

where `<target>` defaults to `./.eidolons/<EIDOLON_NAME>` per §2.1.

§1.8.2 — **MUST**: the `files_written[]` entry recording this file has
`role: "spec"` and a `path` whose basename is `SPEC.md`. A `files_written[]`
entry with `role: "spec"` whose basename is anything other than `SPEC.md` is a
v1.3 conformance violation.

§1.8.3 — **MUST**: exactly one `files_written[]` entry per install has
`role: "spec"`. Zero is a violation (no spec emitted); more than one is a
violation (ambiguous canonical spec).

§1.8.4 — **MAY**: the source repository name the file something other than
`SPEC.md` (e.g., a legacy `ATLAS.md` retained for backward compatibility),
provided the installer renames-on-copy to `SPEC.md` at the destination. EIIS
RECOMMENDS the source file also be named `SPEC.md` to eliminate the
rename-on-copy step.

§1.8.5 — **Compliance grade** (§1.8.1–§1.8.4): warn-only through 2027-04-24
for Eidolons that declare `EIIS_VERSION = 1.0`, `1.1`, or `1.2`; MUST-fail
for Eidolons declaring `EIIS_VERSION = 1.3` or later.

§1.8.6 — **MUST** (v1.4+): `agent.md` MUST also appear in `files_written[]`
with `role: "agent-profile"` and a `path` whose basename is `agent.md`.
Exactly one `role: "agent-profile"` entry per install. Zero is a violation
(no agent profile emitted); more than one is a violation (ambiguous canonical
profile). This pairs with §1.8.3 — every v1.4-conformant install emits
exactly one `agent-profile` and exactly one `spec`.

§1.8.7 — **Compliance grade** (§1.8.6): warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.3`; MUST-fail for `EIIS_VERSION ≥ 1.4`.

---

## §1.9 — Canonical install-target inventory whitelist (v1.4+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.4` or later. v1.0/v1.1/v1.2/v1.3 Eidolons are unaffected.

§1.9.1 — **MUST**: an Eidolon's install target (`<target>/`, default
`./.eidolons/<EIDOLON_NAME>/`) contains, after a successful install, **only**
files and directories listed in the table below. Any other path under
`<target>/` is a v1.4 conformance violation.

| Path | Role | Required / optional | Reference |
|---|---|---|---|
| `<target>/agent.md` | `agent-profile` | **MUST** (D1) | §1.8.6 |
| `<target>/SPEC.md` | `spec` | **MUST** (D1) | §1.8.1 |
| `<target>/install.manifest.json` | `manifest` | **MUST** | §3 |
| `<target>/ECL_VERSION` | `ecl-version` | **MUST** if source declares `ECL_VERSION` (D3) | §3.7.1 |
| `<target>/skills/<skill>.md` | `skill` | MAY (if Eidolon ships skills) | §4.2.4 (v1.3) |
| `<target>/templates/<artifact>.md` | `template` | MAY | §1.6 |
| `<target>/schemas/install.manifest.v1.json` | `other` (vendored schema) | SHOULD | §1.5 |
| `<target>/schemas/<aux>.json` | `other` | MAY | §1.9.2 |

§1.9.2 — **MAY**: an Eidolon vendor additional JSON schemas under
`<target>/schemas/` (e.g. role-specific output schemas). Each MUST appear in
`files_written[]` with `role: "other"`.

§1.9.3 — **MUST NOT**: the install target contain any of the following:

- A per-Eidolon "legacy spec" filename (e.g. `ATLAS.md`, `apivr.md`,
  `REASONER.md`, `IDG.md`, `SPECTRA.md`, `VIGIL.md`, `SCRIBE.md`).
- An install-target copy of the source-repo entry-point files: `AGENTS.md`,
  `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `DESIGN-RATIONALE.md`. These
  remain at the **source-repo** root per §1.1 but MUST NOT be copied into
  `<target>/`.
- A root-level `SKILL.md` (host-dispatch files belong in the host-vendor path
  per §4.2, not under `<target>/`).
- `skills/<phase>/SKILL.md` subdir layout (deprecated by v1.3 §4.2.4.3;
  MUST-fail at v1.4+).
- Any directory under `<target>/` not enumerated in the §1.9.1 table (no
  `hosts/`, `evals/`, `research/`, `tools/`, `commands/` in the install target
  — these are source-repo artefacts).

§1.9.4 — **MUST**: every file under `<target>/` MUST appear in
`install.manifest.json#files_written[]` (no "stowaway" files). Combined with
§1.9.1 this means: writes are whitelisted **and** tracked.

§1.9.5 — **Compliance grade**: warn-only through 2027-04-24 for Eidolons that
declare `EIIS_VERSION ≤ 1.3`; MUST-fail for Eidolons declaring
`EIIS_VERSION = 1.4` or later.

§1.9.6 — **Note on source-repo layout**: §1.1 source-repo MUSTs (`AGENTS.md`,
`CLAUDE.md`, `README.md`, `install.sh`, `agent.md`, `EIIS_VERSION` at the
repo root) are **unchanged** by §1.9. §1.9 governs only the install target.
SPECTRA's source-of-truth at `docs/spectra-methodology/SPEC.md` (§1.8.4
permitted) remains permitted; only the on-disk install-target copy is
constrained.

---

## §2 — `install.sh` flag contract

*(Unchanged from v1.3. See v1.3 spec for full text.)*

---

## §3 — `install.manifest.json` schema

*(§3.1–§3.9 are unchanged from v1.3. §3.7.1 is new in v1.4.)*

§3.3 — **`files_written` shape** (amended v1.4): the `role` enum gains two
new values in v1.4:

| Role value | Meaning |
|---|---|
| `entry-point` | (v1.0) Vendor-neutral entry-point file. |
| `spec` | (v1.3) The canonical full-spec file (`SPEC.md`). |
| `skill` | (v1.0) A methodology skill file. |
| `template` | (v1.0) An output skeleton. |
| `dispatch` | (v1.0) A host-vendor dispatch file (`.claude/agents/<n>.md`, etc.). |
| `manifest` | (v1.0) The install manifest itself. |
| `agent-profile` | **(v1.4)** The always-loaded P0 agent profile (`agent.md`). |
| `ecl-version` | **(v1.4)** The ECL version pinned at install time (`ECL_VERSION`). |
| `other` | (v1.0) Any other file not covered by the above. |

The full enum in `schemas/install.manifest.v1.json` is updated accordingly.

§3.7 — **Optional fields** (amended v1.4): the new optional top-level field
`canonical_inventory_strict` is added:

| Field | Type | Notes |
|---|---|---|
| `canonical_inventory_strict` | boolean | v1.4+. When `true`, this install declares §1.9 strict-inventory conformance. Default behaviour at `EIIS_VERSION >= 1.4` is `true`. Permits opt-out for v1.3-conformant Eidolons mid-migration (declared `false`). |

*(All other §3.7 optional fields are unchanged from v1.3.)*

---

## §3.7.1 — `ECL_VERSION` install-target copy (v1.4+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.4` or later.

§3.7.1.1 — **MUST**: when the Eidolon's source repo declares `ECL_VERSION` at
its root (per v1.2 §4.6 and §1.6), the installer MUST copy it to
`<target>/ECL_VERSION`. The destination file MUST be a verbatim byte-for-byte
copy of the source (no trailing-newline mutation; no transformation).

§3.7.1.2 — **MUST**: the manifest MUST record this file in `files_written[]`
with `role: "ecl-version"`. Exactly one `role: "ecl-version"` entry per
install when present. The same value MAY also appear in
`manifest.ecl_version_emitted` (v1.2 §4.6.4) — these two fields are
independent (one is the on-disk role tag, the other is the declared emission
version).

§3.7.1.3 — **MUST**: the SHA-256 in the `files_written[]` entry equals the
SHA-256 of the source-repo `ECL_VERSION` file.

§3.7.1.4 — **MUST NOT**: an Eidolon whose source repo does **not** declare
`ECL_VERSION` write a `<target>/ECL_VERSION` file. (No empty defaults;
absence is meaningful.)

§3.7.1.5 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.3`; MUST-fail for `EIIS_VERSION ≥ 1.4`.

---

## §4 — Host wiring conventions

*(§4.1, §4.2.4, §4.5, §4.6 are unchanged from v1.3. §4.2.1–§4.2.2 are
retained from v1.3. §4.2.3–§4.2.8 are new in v1.4.)*

### §4.2 — Per-host dispatch files (amended v1.4)

Filename **is** the namespace. One file per Eidolon, one Eidolon per file. No
in-file markers required.

| Host | Path |
|---|---|
| `claude-code` | `.claude/agents/<name>.md` |
| `copilot` | `.github/instructions/<name>.instructions.md` |
| `cursor` | `.cursor/rules/<name>.mdc` |
| `opencode` | `.opencode/agents/<name>.md` |
| `codex` | `.codex/agents/<name>.md` (see also [§4.5](#45--codex-subagent-contract-v11)) |

§4.2.1 — **MUST**: `<name>` matches the lowercase slug in the manifest's
`eidolon` field.

§4.2.2 — **MUST**: each Eidolon owns at most one file per host directory (no
fan-out into multiple files per host with the same Eidolon slug).

§4.2.3 — **MUST** (v1.4+, claude-code): when `claude-code` is in `--hosts`,
the per-Eidolon installer writes `.claude/agents/<EIDOLON_SLUG>.md`. The body
MUST reference both:

- `./.eidolons/<EIDOLON_SLUG>/agent.md` — P0 always-loaded rules (D1).
- `./.eidolons/<EIDOLON_SLUG>/SPEC.md` — deep on-demand methodology spec (D1).

§4.2.4 — **MUST NOT** (v1.4+, claude-code): the body MUST NOT reference any
legacy spec filename whose basename matches the Eidolon's own name in any case
(e.g. `apivr.md`, `ATLAS.md`, `REASONER.md`, `IDG.md`, `SPECTRA.md`,
`VIGIL.md`, `SCRIBE.md`). MUST NOT reference `AGENTS.md` as an
install-target path.

§4.2.5 — **MUST** (v1.4+, claude-code skill references): if the body
references skill files, every `./.eidolons/<EIDOLON_SLUG>/skills/...` path
MUST be flat (`skills/<skill>.md`). MUST NOT reference
`skills/<phase>/SKILL.md` subdir-layout paths.

§4.2.6 — **Canonical heredoc template** for the claude-code host (informative;
implementers MAY adapt prose but MUST satisfy §4.2.3–§4.2.5):

```markdown
---
name: <EIDOLON_SLUG>
description: <one-line description; same as the agent.md frontmatter>
model: <opus|sonnet|haiku>
---

You are <METHODOLOGY_NAME>. Read these two files in order at session start:

1. `./.eidolons/<EIDOLON_SLUG>/agent.md` — always-loaded P0 rules.
2. `./.eidolons/<EIDOLON_SLUG>/SPEC.md` — deep on-demand methodology spec.

Skills live at `./.eidolons/<EIDOLON_SLUG>/skills/<skill>.md` (load on demand).
```

§4.2.7 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.3`; MUST-fail for `EIIS_VERSION ≥ 1.4`. The compliance
check is documented in conformance check `I4`.

§4.2.8 — **Other hosts** (`copilot`, `cursor`, `opencode`, `codex`): the
§4.2.3–§4.2.5 contract applies analogously when those host-vendor surfaces are
emitted. Specific path templates (e.g. `.cursor/rules/<name>.mdc`,
`.codex/agents/<name>.md`) follow each host's convention; the **content**
requirement (both `agent.md` and `SPEC.md` referenced, no legacy names, no
subdir-skill paths) is host-independent.

---

## §5 — Idempotency requirements

*(Unchanged from v1.3. See v1.3 spec for full text.)*

---

## §6 — Versioning & compatibility

*(§6.1–§6.5 are unchanged from v1.3, updated to include v1.4 in §6.2. §6.X
and §6.Y are new sections added in v1.4.)*

§6.2 — **Eidolon ↔ EIIS relationship** (amended v1.4):

- An Eidolon at `EIIS_VERSION 1.0` MUST satisfy v1.0's MUSTs.
- An Eidolon MAY declare `EIIS_VERSION 1.1` and use v1.1 features.
- An Eidolon MAY declare `EIIS_VERSION 1.2` and use v1.2 features.
- An Eidolon MAY declare `EIIS_VERSION 1.3` and use v1.3 features.
- An Eidolon MAY declare `EIIS_VERSION 1.4` and use v1.4 features (§1.9
  canonical inventory whitelist, §1.8.6 two-file canonical pair, §3.7.1
  `ECL_VERSION` target copy, §4.2.3–§4.2.5 host-vendor body contract, §6.X
  cleanup obligation, §6.Y `agent.md` consistency).

§6.2.1 — **v1.0/v1.1/v1.2/v1.3/v1.4 backward compatibility**: v1.0-, v1.1-,
v1.2-, and v1.3-conformant Eidolons pass v1.4 conformance unchanged. The new
MUSTs (§1.9, §1.8.6, §3.7.1, §4.2.3–§4.2.5, §6.X, §6.Y) bind only when an
Eidolon declares `EIIS_VERSION = 1.4`.

§6.3 — **Promotion timeline** for warn-only fields:

| Field | v1.0 | v1.1 | v1.2 | v1.3 | v1.4 |
|---|---|---|---|---|---|
| `EIIS_VERSION` file (D-6) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail | MUST, fail |
| `files_written` populated (D-3) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail | MUST, fail |
| `--shared-dispatch` flag (D-1) | SHOULD | SHOULD | MUST | MUST | MUST |
| Marker convention (D-4) | MUST, fail | MUST, fail | MUST, fail | MUST, fail | MUST, fail |
| `ECL_VERSION` format (E0) | n/a | n/a | MUST, warn-only | MUST, warn-only | MUST, warn-only |
| `ecl_version_emitted` ↔ `ECL_VERSION` (E1) | n/a | n/a | WARN | WARN | WARN |
| Spec filename = `SPEC.md` (S1) | n/a | n/a | n/a | MUST, fail | MUST, fail |
| `spec_file` field present (S2) | n/a | n/a | n/a | MUST, fail | MUST, fail |
| Skills flat source-of-truth (K1) | n/a | n/a | n/a | MUST, fail | MUST, fail |
| Skills `vendor_sha256` = `source_sha256` (K2) | n/a | n/a | n/a | MUST, fail | MUST, fail |
| Skills `vendor_path` on disk (K3) | n/a | n/a | n/a | WARN | WARN |
| Install-target inventory whitelist (I1) | n/a | n/a | n/a | n/a | MUST, fail |
| Two-file canonical pair: `agent-profile` (I2) | n/a | n/a | n/a | n/a | MUST, fail |
| `ECL_VERSION` target copy (I3) | n/a | n/a | n/a | n/a | MUST, fail |
| Host-vendor refs: `agent.md` + `SPEC.md` (I4) | n/a | n/a | n/a | n/a | MUST, fail |
| `agent.md` skill-path consistency (I5) | n/a | n/a | n/a | n/a | MUST, fail |

§6.4 — **Hard-fail promotion target date**: 2027-04-24.

§6.5 — `EIIS_VERSION` file format: a single line, bare SemVer
(`<MAJOR>.<MINOR>` or `<MAJOR>.<MINOR>.<PATCH>`). No `v` prefix, no suffix. A
trailing newline is permitted but not required.

---

## §6.X — Install-target cleanup obligation (v1.4+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.4` or later.

§6.X.1 — **MUST**: after a successful install, the only files under
`<target>/` are those listed in the current run's
`install.manifest.json#files_written[]`. Equivalently: the installer MUST
sweep any file under `<target>/` that is **not** in the current
`files_written[]` set before terminating.

§6.X.2 — **Rationale**: combined with §1.9, this guarantees that upgrading
from an earlier EIIS version (or from an earlier release of the same Eidolon
that shipped a different inventory) does not leave non-whitelisted files on
disk. Replaces the per-Eidolon ad-hoc `cleanup_legacy_v1_2` of v1.3.1 with a
contracted, manifest-driven model.

§6.X.3 — **MUST NOT**: the cleanup pass touch any path outside `<target>/`.
Host-vendor paths (`.claude/agents/<n>.md`, `.claude/skills/<n>-<skill>/SKILL.md`)
are governed separately by their respective host-wiring sections;
cleanup-on-upgrade for host paths is host-specific and **out of scope** for
§6.X.

§6.X.4 — **Reference implementation**: see Appendix A. The reference
implementation is bash 3.2 compatible.

§6.X.5 — **MAY**: an installer use a hardcoded "files we used to install but
no longer do" list **in addition** to (but not in place of) the
manifest-diff sweep. The manifest-diff sweep is the normative requirement;
hardcoded lists are a defensive belt-and-braces option.

§6.X.6 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.3`; MUST-fail for `EIIS_VERSION ≥ 1.4`.

---

## §6.Y — `agent.md` content consistency (v1.4+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.4` or later.

§6.Y.1 — **MUST**: every reference of the form `skills/<skill>.md` (or
`<target>/skills/<skill>.md`) inside `<target>/agent.md` MUST resolve to a
path that appears in `files_written[]` (i.e. a skill that was actually emitted
by this install).

§6.Y.2 — **MUST NOT**: `<target>/agent.md` reference a
`skills/<phase>/SKILL.md` subdir-layout path. v1.3 §4.2.4.3 deprecates that
layout; v1.4 promotes the agent.md consistency check to MUST-fail.

§6.Y.3 — **MUST NOT**: `<target>/agent.md` reference any per-Eidolon legacy
spec filename (basenames that match `<EIDOLON_SLUG>.md` case-insensitively,
e.g. `apivr.md`, `ATLAS.md`). Spec references MUST use `SPEC.md` (or relative
`./SPEC.md` / sibling references).

§6.Y.4 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.3`; MUST-fail for `EIIS_VERSION ≥ 1.4`.

---

## §7 — Non-goals

EIIS v1.4 does **NOT** mandate, define, or constrain (in addition to v1.3
non-goals):

- **Source-repo layout changes.** §1.1 source-repo MUSTs are unchanged. §1.9
  governs only the install target. SPECTRA's `docs/spectra-methodology/SPEC.md`
  source-of-truth stays where it is — §1.9.6 explicitly permits this.
- **Moving FORGE's source-repo `SKILL.md`.** That file is the Codex
  package-discovery convention at the FORGE source-repo root. Only the
  install-target copy is governed by §1.9.
- **Adding Codex host-vendor path emission to any Eidolon.** Deferred.
- **Agent.md token budgets, P0 rules, or methodology content** — only
  filename/path strings inside agent.md are affected by §6.Y.
- **Cleanup-on-upgrade for host-vendor paths** (`.claude/agents/<n>.md`,
  `.claude/skills/<n>-<skill>/SKILL.md`). §6.X scopes the cleanup obligation
  to `<target>/` only.
- **Cross-host vendor path bodies beyond `.claude/`**. §4.2.8 flags the
  analogous requirement for other hosts but does not specify per-host path
  details; deferred to a follow-up spec.
- **Nexus CLI changes.** No CLI changes are required for the inventory
  tightening — per-Eidolon installers own all install-target writes.

---

## Citations

1. RFC 2119 — Key words for use in RFCs to Indicate Requirement Levels.
   <https://www.rfc-editor.org/rfc/rfc2119>
2. RFC 8174 / BCP 14 — Ambiguity of Uppercase vs Lowercase in RFC 2119
   Key Words. <https://www.rfc-editor.org/rfc/rfc8174>
3. RFC 3339 — Date and Time on the Internet: Timestamps.
   <https://www.rfc-editor.org/rfc/rfc3339>
4. SemVer 2.0.0. <https://semver.org/spec/v2.0.0.html>
5. JSON Schema draft-2020-12.
   <https://json-schema.org/draft/2020-12/schema>
6. Keep a Changelog 1.1.0.
   <https://keepachangelog.com/en/1.1.0/>
7. Conventional Commits 1.0.0.
   <https://www.conventionalcommits.org/en/v1.0.0/>

---

## Appendix A — `canonical_inventory_sweep` reference implementation

Bash 3.2 compatible. Manifest-driven. Invoked once, **after** all writes
complete and **before** `install.manifest.json` is finalized for emission.

```bash
# canonical_inventory_sweep <target>
#
# Remove every file under <target>/ that is not present in the in-memory
# allow-set FILES_WRITTEN_PATHS. The allow-set is maintained by add_fw()
# (or the equivalent helper) during the install; each successful write
# appends its target-relative path to FILES_WRITTEN_PATHS.
#
# Bash 3.2 compatible: indexed array, no associative arrays, no readarray.
# Idempotent: re-running on a clean target is a no-op.
#
# Assumes the per-Eidolon installer maintains:
#   FILES_WRITTEN_PATHS  — indexed array of target-relative paths written
#                          this run (matches files_written[].path).
canonical_inventory_sweep() {
  local target="$1"
  local file_rel
  local found
  local known

  if [ -z "${target}" ] || [ ! -d "${target}" ]; then
    return 0
  fi

  # Walk every file under <target>/; for each, test membership in the allow-set.
  # find ... -print0 is bash 3.2 safe with `while IFS= read -r -d '' file`.
  find "${target}" -type f -print0 | while IFS= read -r -d '' file; do
    # Compute the target-relative path (strip "${target}/" prefix).
    file_rel="${file#${target}/}"

    found=0
    for known in "${FILES_WRITTEN_PATHS[@]}"; do
      # FILES_WRITTEN_PATHS entries are typically consumer-relative
      # (e.g. ".eidolons/apivr/SPEC.md"). Compare by basename + parent-suffix.
      case "${known}" in
        *"/${file_rel}"|"${file_rel}")
          found=1
          break
          ;;
      esac
    done

    if [ "${found}" -eq 0 ]; then
      rm -f "${file}"
      echo "[sweep] removed non-whitelisted file: ${file}" >&2
    fi
  done

  # Remove any empty directories left after the sweep.
  find "${target}" -mindepth 1 -type d -empty -delete 2>/dev/null || true

  return 0
}
```

**Notes:**

- `FILES_WRITTEN_PATHS` is an indexed array maintained by each installer. The
  per-Eidolon `copy_file` or `wire_skill` helper appends each written path to
  this array.
- The comparison (`case *"/${file_rel}"|"${file_rel}"`) tolerates both
  consumer-relative paths (`.eidolons/apivr/SPEC.md`) and target-relative
  paths (`SPEC.md`) in `FILES_WRITTEN_PATHS`.
- The function is called **once**, at the end of the install, **before** the
  manifest is written. Alternatively, the manifest write may be the **last**
  entry in `FILES_WRITTEN_PATHS` so the sweep never sees it as a non-whitelisted
  file — implement whichever ordering is cleaner per-installer.
- The `find ... -empty -delete` is a POSIX `find(1)` flag, not a bash builtin;
  the trailing `|| true` defends against `find` warnings on non-empty special
  dirs.

---

## Appendix B — Changes from v1.3

**New normative sections:**

- §1.9 — Canonical install-target inventory whitelist (MUST list of allowed
  paths; MUST-fail at `EIIS_VERSION ≥ 1.4`).
- §3.7.1 — `ECL_VERSION` install-target copy MUST when source declares it;
  `role: "ecl-version"` in `files_written[]`.
- §6.X — Install-target cleanup obligation (manifest-driven sweep; replaces
  ad-hoc per-Eidolon cleanup lists).
- §6.Y — `agent.md` content consistency (skill paths MUST resolve to
  `files_written[]` entries; no subdir-layout or legacy-spec references).

**Amended normative sections:**

- §1.8 — amended: §1.8.6 adds `agent.md` MUST appear in `files_written[]`
  with `role: "agent-profile"` (exactly one per install). §1.8.7 sets
  compliance grade.
- §4.2 — amended: §4.2.3–§4.2.5 add claude-code body contract (MUST reference
  both `agent.md` and `SPEC.md`; MUST NOT reference legacy filenames or subdir
  skill paths). §4.2.6 canonical heredoc template. §4.2.7 compliance grade.
  §4.2.8 other-hosts analogue.

**Schema additions (`schemas/install.manifest.v1.json`):**

- `role` enum: gains `"agent-profile"` and `"ecl-version"`.
- Top-level optional field `canonical_inventory_strict` (boolean).

**Conformance checker additions (`conformance/check.sh` + `lib/`):**

- `I1` — Inventory whitelist (MUST-fail ≥ 1.4; warn-only ≤ 1.3).
- `I2` — Two-file canonical pair: `agent-profile` + `spec` each exactly once
  (MUST-fail ≥ 1.4).
- `I3` — `ECL_VERSION` target copy when source declares it (MUST-fail ≥ 1.4).
- `I4` — Host-vendor refs: `.claude/agents/<n>.md` references both `agent.md`
  and `SPEC.md`; no legacy names (MUST-fail ≥ 1.4).
- `I5` — `agent.md` skill-path consistency (MUST-fail ≥ 1.4).

**Backward compatibility**: all v1.3 and earlier Eidolons pass the v1.4
conformance checker unchanged. All I-series MUSTs are gated on
`EIIS_VERSION ≥ 1.4`; warn-only at ≤ 1.3.
