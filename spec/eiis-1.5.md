# EIIS — Eidolons Individual Install Standard

**Version:** 1.5
**Status:** Stable
**Published:** 2026-07-02
**Editors:** Rynaro and the Eidolons contributors
**License:** Apache-2.0

<!-- Note to editors: v1.5 adds two new normative surfaces: the `hook_event`
manifest field and the host-hook wiring split. Placement: `hook_event` goes
at §3.7.2 (sibling to v1.4's §3.7.1 ECL_VERSION copy — both are additions
under §3.7's "optional fields" umbrella). Hook wiring conventions go at §4.7
(next unused top-level slot after v1.2's §4.6 ECL composition clause). The
inventory whitelist amendment stays at §1.9 (amending, not replacing, the
section v1.4 introduced) with new sub-clauses §1.9.7-§1.9.9. The new
conformance gate is `I6`, the next available ID after v1.4's `I1`-`I5`. -->

## Normative keywords

The keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**,
**SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in
this document are to be interpreted as described in
[BCP 14](https://www.rfc-editor.org/rfc/rfc8174)
([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119),
[RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)) when, and only when,
they appear in all capitals, as shown here.

## Status of this document

This is EIIS v1.5, an additive minor release over v1.4. v1.5 introduces
normative changes for Eidolons that declare `EIIS_VERSION = 1.5`, closing
the install-contract gap around host session/prompt hooks (e.g. a Claude
Code `SessionStart` or `UserPromptSubmit` shim): previously these files had
no home in EIIS, so they could not be inventory-tracked, swept on uninstall,
or doctor-verified against a manifest.

- **§1.9 — Inventory whitelist amendment (v1.5)**: the §1.9.1 table gains a
  `<target>/hooks/<name>.sh` row. §1.9.7–§1.9.8 add the flat-layout MUST /
  MUST NOT for `hooks/`.

- **§3.3 — `role` enum amendment (v1.5)**: gains `"hook"`.

- **§3.7.2 — `hook_event` field (v1.5)**: every `files_written[]` entry with
  `role: "hook"` MUST carry a `hook_event` naming which host lifecycle event
  the shim binds to (`session-start` | `prompt-submit` | `pre-tool` | `stop`).

- **§4.7 — Hook wiring conventions (v1.5)**: splits the hook **shim file**
  (tracked as `files_written[]` role `hook`) from the **host-config
  registration** that wires the shim into the host (tracked as
  `files_written[]` role `dispatch`, under the existing host-wiring/marker
  rules — no new manifest surface for the registration itself). Per-Eidolon
  installers still write only to the consumer project's working directory;
  hooks introduce no new write surface.

- **§6.X.7 — Hook sweep clarification (v1.5)**: the §6.X manifest-driven
  cleanup sweep removes `role: "hook"` files exactly as it removes files of
  any other role. Declarative — the generic sweep already covers this; the
  clause exists to make the coverage explicit now that hooks are a named
  install-contract surface.

v1.0-, v1.1-, v1.2-, v1.3-, and v1.4-conformant Eidolons remain conformant
under v1.5 without modification. The new MUSTs bind **only** when an Eidolon
declares `EIIS_VERSION = 1.5` or later, mirroring the backward-compat
pattern used in v1.1 (Codex addendum), v1.2 (ECL composition), v1.3
(canonical SPEC.md + skills dual-write), and v1.4 (canonical inventory +
agent-profile + `ECL_VERSION` + host-vendor body contract + cleanup +
`agent.md` consistency). See [§6](#6--versioning--compatibility).

## Table of contents

- [§1 — Repo Layout](#1--repo-layout) (v1.0 baseline; §1.7, §1.8 from v1.3, §1.9 from v1.4)
- [§1.8 — Canonical full-spec filename](#18--canonical-full-spec-filename) (unchanged from v1.4)
- [§1.9 — Canonical install-target inventory whitelist (amended v1.5)](#19--canonical-install-target-inventory-whitelist-amended-v15)
- [§2 — `install.sh` flag contract](#2--installsh-flag-contract)
- [§3 — `install.manifest.json` schema](#3--installmanifestjson-schema)
- [§3.7.1 — `ECL_VERSION` install-target copy (v1.4+)](#371--ecl_version-install-target-copy-v14)
- [§3.7.2 — `hook_event` field (v1.5+)](#372--hook_event-field-v15)
- [§4 — Host wiring conventions](#4--host-wiring-conventions)
- [§4.2 — Per-host dispatch files](#42--per-host-dispatch-files) (unchanged from v1.4)
- [§4.7 — Hook wiring conventions (v1.5+)](#47--hook-wiring-conventions-v15)
- [§5 — Idempotency requirements](#5--idempotency-requirements)
- [§6 — Versioning & compatibility](#6--versioning--compatibility)
- [§6.X — Install-target cleanup obligation](#6x--install-target-cleanup-obligation) (v1.4+; hook sweep note added v1.5)
- [§6.Y — `agent.md` content consistency (v1.4+)](#6y--agentmd-content-consistency-v14)
- [§7 — Non-goals](#7--non-goals)
- [Citations](#citations)
- [Appendix A — `canonical_inventory_sweep` reference implementation](#appendix-a--canonical_inventory_sweep-reference-implementation)
- [Appendix B — Changes from v1.4](#appendix-b--changes-from-v14)

---

## §1 — Repo Layout

*(Unchanged from v1.4. Reproduced here for completeness.)*

A conformant Eidolon repository **MUST** contain at minimum, all at the
repository root:

| Path | Purpose | Stability |
|---|---|---|
| `agent.md` | Always-loaded entry-point document. SHOULD fit within an estimated 1000-token budget. | [Stable] |
| `AGENTS.md` | Vendor-neutral methodology summary. | [Stable] |
| `CLAUDE.md` | Claude Code surface document. | [Stable] |
| `README.md` | Human-readable repo introduction. | [Stable] |
| `install.sh` | Executable installer script (`bash`, with the executable bit set). | [Stable] |
| `EIIS_VERSION` | Single-line file containing a bare SemVer string declaring which EIIS minor the repo targets (e.g. `1.5`). | [Stable] |

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

## §1.8 — Canonical full-spec filename

*(Unchanged from v1.4. See v1.4 spec for full text: §1.8.1–§1.8.7 — the
two-file canonical pair, `agent.md` MUST appear in `files_written[]` with
`role: "agent-profile"`, `SPEC.md` MUST appear with `role: "spec"`, and the
associated compliance grades.)*

---

## §1.9 — Canonical install-target inventory whitelist (amended v1.5)

This section is **normative**. §1.9.1–§1.9.6 are unchanged from v1.4 and
reproduced here for completeness, with one addition: the whitelist table in
§1.9.1 gains a new row for `hooks/` (v1.5). §1.9.7–§1.9.9 are new in v1.5.

§1.9.1 — **MUST**: an Eidolon's install target (`<target>/`, default
`./.eidolons/<EIDOLON_NAME>/`) contains, after a successful install, **only**
files and directories listed in the table below. Any other path under
`<target>/` is a v1.4+ conformance violation.

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
| `<target>/hooks/<name>.sh` | `hook` | MAY (if Eidolon ships hooks) | **(v1.5)** §1.9.7, §3.7.2 |

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
  `evals/`, `research/`, `tools/`, `commands/` in the install target — these
  are source-repo artefacts. `hooks/` is enumerated as of v1.5 — see §1.9.7 —
  and is **not** permitted for Eidolons declaring `EIIS_VERSION ≤ 1.4`).

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

§1.9.7 — **MAY** (v1.5+): an Eidolon ship one or more hook shim files at
`<target>/hooks/<name>.sh`, where `<name>` matches `^[a-z][a-z0-9-]*$` and
the file sits directly under `hooks/` with no further subdirectory nesting
(flat layout, mirroring `skills/` and `templates/` in §1.9.1). Each such file
MUST appear in `files_written[]` with `role: "hook"` and a valid
`hook_event` (§3.7.2). `.sh` is the required extension — hook shims are
ordinary shell scripts, consistent with `install.sh` itself; nothing in
§1.9.7 constrains what the script does internally (e.g. it MAY `exec` into
another interpreter).

§1.9.8 — **MUST NOT** (v1.5+): a subdirectory nested under `<target>/hooks/`
(e.g. `hooks/session/start.sh`). Same flat-layout rule §1.9.1 already applies
to `skills/` and `templates/`.

§1.9.9 — **Compliance grade** (§1.9.7–§1.9.8): warn-only through 2027-04-24
for Eidolons that declare `EIIS_VERSION ≤ 1.4`; MUST-fail for Eidolons
declaring `EIIS_VERSION = 1.5` or later. Checked by conformance gate `I6`
(see Appendix B).

---

## §2 — `install.sh` flag contract

*(Unchanged from v1.3. See v1.3 spec for full text.)*

---

## §3 — `install.manifest.json` schema

*(§3.1–§3.9 are unchanged from v1.4, except §3.3's role enum table, which
gains one new value below. §3.7.2 is new in v1.5.)*

§3.3 — **`files_written` shape** (amended v1.5): the `role` enum gains one
new value in v1.5:

| Role value | Meaning |
|---|---|
| `entry-point` | (v1.0) Vendor-neutral entry-point file. |
| `spec` | (v1.3) The canonical full-spec file (`SPEC.md`). |
| `skill` | (v1.0) A methodology skill file. |
| `template` | (v1.0) An output skeleton. |
| `dispatch` | (v1.0) A host-vendor dispatch file (`.claude/agents/<n>.md`, etc.). As of v1.5, also covers host-config hook-registration edits (§4.7.2). |
| `manifest` | (v1.0) The install manifest itself. |
| `agent-profile` | (v1.4) The always-loaded P0 agent profile (`agent.md`). |
| `ecl-version` | (v1.4) The ECL version pinned at install time (`ECL_VERSION`). |
| `hook` | **(v1.5)** A host-hook shim file under `<target>/hooks/` (§1.9.7, §4.7.1). Requires `hook_event` (§3.7.2). |
| `other` | (v1.0) Any other file not covered by the above. |

The full enum in `schemas/install.manifest.v1.json` is updated accordingly.

§3.7 — **Optional fields** (unchanged from v1.4): see v1.4 spec for the
`canonical_inventory_strict` field definition. `hook_event` is a **sibling**
optional field, defined in its own section below (§3.7.2) because — unlike
`canonical_inventory_strict`, which is top-level — `hook_event` lives inside
each `files_written[]` item.

---

## §3.7.1 — `ECL_VERSION` install-target copy (v1.4+)

*(Unchanged from v1.4. See v1.4 spec for full text.)*

---

## §3.7.2 — `hook_event` field (v1.5+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.5` or later.

§3.7.2.1 — **MUST**: every `files_written[]` entry with `role: "hook"`
carries a `hook_event` field.

§3.7.2.2 — **MUST**: `hook_event` is one of exactly four values:

- `session-start`
- `prompt-submit`
- `pre-tool`
- `stop`

Any other value on a `role: "hook"` entry is a conformance violation. This
is a **closed** enum — extending it requires a spec revision, mirroring
ECL's closed-performative-set precedent.

§3.7.2.3 — **MAY** (schema level): `hook_event` MAY appear on `files_written[]`
entries whose `role` is not `"hook"`; the field is schema-optional for every
role (the JSON Schema does not encode role-conditional requiredness). §3.7.2.1's
MUST binds only for `role: "hook"` entries and is enforced by the conformance
checker, not by JSON Schema `if`/`then` — the same division of labour EIIS
has used since v1.3 for cross-field MUSTs (§1.8.2, §1.8.6, §3.7.1.2).

§3.7.2.4 — **MUST NOT**: an entry with `role: "hook"` and an empty or
missing `hook_event` be treated as conformant. Absence and invalidity are
both violations (no implicit default event).

§3.7.2.5 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.4`; MUST-fail for `EIIS_VERSION ≥ 1.5`. Checked by
conformance gate `I6`.

---

## §4 — Host wiring conventions

*(§4.1–§4.6 are unchanged from v1.4; see v1.4 spec for full text. §4.7 is
new in v1.5.)*

### §4.2 — Per-host dispatch files

*(Unchanged from v1.4. See v1.4 spec for full text: §4.2.1–§4.2.8 — the
filename-as-namespace convention and the claude-code body contract requiring
references to both `agent.md` and `SPEC.md`.)*

---

## §4.7 — Hook wiring conventions (v1.5+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.5` or later. It resolves the gap named in this release's
motivation: host session/prompt hooks (e.g. a Claude Code `SessionStart` or
`UserPromptSubmit` shim) previously had no home in EIIS — they could not be
inventory-tracked (§1.9), swept on uninstall (§6.X), or doctor-verified
against a manifest.

§4.7.1 — **MUST**: the hook **shim file** — the executable script a host
invokes at the named lifecycle event — is written under the install target
at `<target>/hooks/<name>.sh` (§1.9.7) and recorded in `files_written[]`
with `role: "hook"` and the matching `hook_event` (§3.7.2).

§4.7.2 — **MUST**: the **host-config wiring** — the edit that registers the
shim with the host (e.g. an entry appended to a Claude Code
`.claude/settings.json` `hooks` array, or the host-equivalent registration
surface) is tracked the same way EIIS already tracks every other host-config
edit: as a `files_written[]` entry with `role: "dispatch"`, subject to the
existing marker-convention rules (§4.1) whenever the target file is shared
across Eidolons. `role: "hook"` is reserved exclusively for the shim file
(§4.7.1) — the host-config registration is never itself tagged `role: "hook"`.
This mirrors how §1.4's host-vendor dispatch files and marker-bounded
shared-dispatch blocks are both tracked as `role: "dispatch"` regardless of
whether the target file is Eidolon-exclusive or shared.

§4.7.3 — **MUST NOT**: an installer register a hook shim with a host without
also writing that shim under `<target>/hooks/` and recording it in
`files_written[]`. There is no "host registration only, no on-disk shim"
install shape — every host hook registration MUST be backed by an on-disk,
manifest-tracked shim.

§4.7.4 — **MUST NOT**: hook wiring introduce a new write surface. Per-Eidolon
installers write only to the consumer project's working directory — the
invariant that has held since v1.0. A hook shim and its host-config
registration are ordinary cwd writes, identical in kind to a per-host
dispatch file (§4.2) or a marker-bounded shared-dispatch block (§4.1). v1.5
grants no installer the ability to write outside cwd (e.g. no writes to
`$EIDOLONS_HOME` or any global path). See §7.

§4.7.5 — **Non-goal**: EIIS does not define a hook's **execution semantics**
— its stdin/stdout contract, exit-code meaning, or the host's own hook
payload JSON schema (e.g. Claude Code's `SessionStart`/`UserPromptSubmit`
hook contract). That is host-specific and out of scope. EIIS governs only
whether the shim is present, tracked, and swept correctly — not what it
does when invoked. See §7.

§4.7.6 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.4`; MUST-fail for `EIIS_VERSION ≥ 1.5`.

---

## §5 — Idempotency requirements

*(Unchanged from v1.3. See v1.3 spec for full text.)*

---

## §6 — Versioning & compatibility

*(§6.1, §6.5 are unchanged from v1.3. §6.2, §6.3 are updated to include
v1.5. §6.X gains a new §6.X.7 clause in v1.5. §6.Y is unchanged from v1.4.)*

§6.2 — **Eidolon ↔ EIIS relationship** (amended v1.5):

- An Eidolon at `EIIS_VERSION 1.0` MUST satisfy v1.0's MUSTs.
- An Eidolon MAY declare `EIIS_VERSION 1.1` and use v1.1 features.
- An Eidolon MAY declare `EIIS_VERSION 1.2` and use v1.2 features.
- An Eidolon MAY declare `EIIS_VERSION 1.3` and use v1.3 features.
- An Eidolon MAY declare `EIIS_VERSION 1.4` and use v1.4 features (§1.9
  canonical inventory whitelist, §1.8.6 two-file canonical pair, §3.7.1
  `ECL_VERSION` target copy, §4.2.3–§4.2.5 host-vendor body contract, §6.X
  cleanup obligation, §6.Y `agent.md` consistency).
- An Eidolon MAY declare `EIIS_VERSION 1.5` and use v1.5 features (§3.7.2
  `hook_event` field, §1.9.7–§1.9.9 `hooks/` inventory whitelist, §4.7 hook
  wiring conventions, §6.X.7 hook sweep clarification).

§6.2.1 — **v1.0–v1.5 backward compatibility**: v1.0-, v1.1-, v1.2-, v1.3-,
and v1.4-conformant Eidolons pass v1.5 conformance unchanged. The new MUSTs
(§3.7.2, §1.9.7–§1.9.9, §4.7) bind only when an Eidolon declares
`EIIS_VERSION = 1.5`.

§6.3 — **Promotion timeline** for warn-only fields:

| Field | v1.0 | v1.1 | v1.2 | v1.3 | v1.4 | v1.5 |
|---|---|---|---|---|---|---|
| `EIIS_VERSION` file (D-6) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail | MUST, fail | MUST, fail |
| `files_written` populated (D-3) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail | MUST, fail | MUST, fail |
| `--shared-dispatch` flag (D-1) | SHOULD | SHOULD | MUST | MUST | MUST | MUST |
| Marker convention (D-4) | MUST, fail | MUST, fail | MUST, fail | MUST, fail | MUST, fail | MUST, fail |
| `ECL_VERSION` format (E0) | n/a | n/a | MUST, warn-only | MUST, warn-only | MUST, warn-only | MUST, warn-only |
| `ecl_version_emitted` ↔ `ECL_VERSION` (E1) | n/a | n/a | WARN | WARN | WARN | WARN |
| Spec filename = `SPEC.md` (S1) | n/a | n/a | n/a | MUST, fail | MUST, fail | MUST, fail |
| `spec_file` field present (S2) | n/a | n/a | n/a | MUST, fail | MUST, fail | MUST, fail |
| Skills flat source-of-truth (K1) | n/a | n/a | n/a | MUST, fail | MUST, fail | MUST, fail |
| Skills `vendor_sha256` = `source_sha256` (K2) | n/a | n/a | n/a | MUST, fail | MUST, fail | MUST, fail |
| Skills `vendor_path` on disk (K3) | n/a | n/a | n/a | WARN | WARN | WARN |
| Install-target inventory whitelist (I1) | n/a | n/a | n/a | n/a | MUST, fail | MUST, fail |
| Two-file canonical pair: `agent-profile` (I2) | n/a | n/a | n/a | n/a | MUST, fail | MUST, fail |
| `ECL_VERSION` target copy (I3) | n/a | n/a | n/a | n/a | MUST, fail | MUST, fail |
| Host-vendor refs: `agent.md` + `SPEC.md` (I4) | n/a | n/a | n/a | n/a | MUST, fail | MUST, fail |
| `agent.md` skill-path consistency (I5) | n/a | n/a | n/a | n/a | MUST, fail | MUST, fail |
| `hook_event` validity + `hooks/` sweep symmetry (I6) | n/a | n/a | n/a | n/a | n/a | **MUST, fail** |

§6.4 — **Hard-fail promotion target date**: 2027-04-24. Unchanged from
v1.0–v1.4. This is a single global clock shared by every warn-only field in
§6.3, not a per-version date — v1.5 adds new rows to the existing table, it
does not open a new promotion window. See Appendix B for the explicit
rationale.

§6.5 — `EIIS_VERSION` file format: a single line, bare SemVer
(`<MAJOR>.<MINOR>` or `<MAJOR>.<MINOR>.<PATCH>`). No `v` prefix, no suffix. A
trailing newline is permitted but not required.

---

## §6.X — Install-target cleanup obligation

*(§6.X.1–§6.X.6 are unchanged from v1.4; reproduced here for completeness.
§6.X.7 is new in v1.5.)*

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

§6.X.7 — **MUST** (v1.5+, clarifying): the §6.X.1 manifest-driven sweep
applies to `role: "hook"` files exactly as it applies to files of any other
role. A hook shim under `<target>/hooks/` that is not in the current run's
`files_written[]` set MUST be removed by the same sweep pass — there is no
hook-specific carve-out. This clause is declarative, not a new mechanism:
the generic sweep (Appendix A) already covers hook files by construction
(it operates on `FILES_WRITTEN_PATHS` regardless of role); §6.X.7 exists to
state the coverage explicitly now that hooks are a named install-contract
surface. Compliance grade matches §1.9.9 / §3.7.2.5: warn-only through
2027-04-24 for `EIIS_VERSION ≤ 1.4`; MUST-fail for `EIIS_VERSION ≥ 1.5`.

---

## §6.Y — `agent.md` content consistency (v1.4+)

*(Unchanged from v1.4. See v1.4 spec for full text. §6.Y is not amended by
v1.5 — hook shims are not referenced from `agent.md` and are out of §6.Y's
scope.)*

---

## §7 — Non-goals

EIIS v1.5 does **NOT** mandate, define, or constrain (in addition to v1.4
non-goals):

- **Hook execution semantics.** EIIS governs only the install-contract
  surface of a hook (presence under `<target>/hooks/`, manifest tracking,
  sweep-on-cleanup). The shim's stdin/stdout contract, exit-code semantics,
  and the host's own hook payload JSON schema (e.g. Claude Code's
  `SessionStart`/`UserPromptSubmit` hook contract) are host-specific and out
  of EIIS's scope. See §4.7.5.
- **Hook script implementation.** §1.9.7 fixes the on-disk location and
  extension (`hooks/<name>.sh`) for inventory-whitelist purposes; it does
  not constrain what the script does internally, which interpreter it
  ultimately delegates to, or how many hooks an Eidolon ships.
- **Hook scheduling, ordering, or host registration format.** How a host
  orders multiple Eidolons' hooks bound to the same `hook_event`, or the
  exact shape of the host's own registration file (e.g. Claude Code
  `settings.json`'s `hooks` array schema), is host-specific. §4.7.2 only
  requires that the registration edit be tracked as `role: "dispatch"`;
  it does not define the registration's internal shape.
- **New `hook_event` values beyond the four defined in §3.7.2.2.** The enum
  is closed; extending it is a spec revision, not a per-Eidolon extension
  point.
- **Nexus CLI changes.** No CLI changes are required for hook wiring —
  per-Eidolon installers own all install-target and host-config writes, same
  as every prior EIIS version.

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
- **v1.5 note**: files with `role: "hook"` under `<target>/hooks/` are swept
  identically — no special-casing is required in `canonical_inventory_sweep`,
  since the function already operates on `FILES_WRITTEN_PATHS` irrespective
  of role. See §6.X.7.

---

## Appendix B — Changes from v1.4

**New normative sections:**

- §3.7.2 — `hook_event` field on `role: "hook"` `files_written[]` entries;
  closed four-member enum (`session-start`, `prompt-submit`, `pre-tool`,
  `stop`).
- §4.7 — Hook wiring conventions: splits the shim file (`files_written[]`
  role `hook`) from the host-config registration (`files_written[]` role
  `dispatch`, existing host-wiring rules unchanged); explicit no-new-write-
  surface statement (§4.7.4); hook execution semantics declared a non-goal
  (§4.7.5).
- §6.X.7 — Declarative clarification that the manifest-driven cleanup sweep
  (§6.X) covers `role: "hook"` files identically to every other role.

**Amended normative sections:**

- §1.9 — amended: §1.9.1 whitelist table gains a `hooks/<name>.sh` row.
  §1.9.7–§1.9.8 add the flat-layout MUST / MUST NOT for `hooks/`. §1.9.9
  sets compliance grade.
- §3.3 — amended: `role` enum gains `"hook"`.

**Schema additions (`schemas/install.manifest.v1.json`):**

- `role` enum: gains `"hook"`.
- `files_written[]` items gain optional field `hook_event` (closed enum:
  `session-start`, `prompt-submit`, `pre-tool`, `stop`).
- No schema version bump (`v1` retained) — additive-optional, the same
  precedent v1.4 set for the `agent-profile`/`ecl-version` roles and the
  `canonical_inventory_strict` field.

**Conformance checker additions (`conformance/check.sh` + `lib/`):**

- `I6` — every `role: "hook"` entry has a valid `hook_event`; every file
  under `<target>/hooks/` is manifest-declared with `role: "hook"` (sweep
  symmetry). MUST-fail for `EIIS_VERSION ≥ 1.5`; warn-only for `≤ 1.4`.
- `checks-inventory.sh`'s §1.9.1 whitelist walk (`I1`) gains a `hooks/*.sh`
  branch, active only when the target declares `EIIS_VERSION ≥ 1.5` — a v1.4
  Eidolon shipping a `hooks/` directory still fails `I1`; the path was not
  whitelisted before v1.5.
- `checks-manifest.sh`'s `M13` role-enum check is updated to accept `"hook"`
  without MUST-failing (the same treatment v1.4 gave `agent-profile` and
  `ecl-version`).

**Backward compatibility**: all v1.4 and earlier Eidolons pass the v1.5
conformance checker unchanged. `I6` is gated on `EIIS_VERSION ≥ 1.5`;
warn-only at `≤ 1.4`. The hard-fail promotion date for all warn-only fields
(§6.4) is unchanged at 2027-04-24 — v1.5 adds new rows to the single global
promotion clock established at v1.0, it does not open a new promotion
window or introduce a per-version date.
