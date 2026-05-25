# EIIS — Eidolons Individual Install Standard

**Version:** 1.3
**Status:** Stable
**Published:** 2026-05-25
**Editors:** Rynaro and the Eidolons contributors
**License:** Apache-2.0

## Normative keywords

The keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**,
**SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in
this document are to be interpreted as described in
[BCP 14](https://www.rfc-editor.org/rfc/rfc8174)
([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119),
[RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)) when, and only when,
they appear in all capitals, as shown here.

## Status of this document

This is EIIS v1.3, an additive minor release over v1.2. v1.3 introduces two
normative requirements for Eidolons that declare `EIIS_VERSION = 1.3`:

- **§1.8 — Canonical full-spec filename**: every Eidolon installer MUST write
  its full methodology spec at exactly `<target>/SPEC.md`. This replaces the
  prior ad-hoc naming convention (`ATLAS.md`, `VIGIL.md`, `REASONER.md`, etc.)
  with a single uniform filename.

- **§4.2.4 — Skills dual-write**: every Eidolon that ships skill files MUST
  write each skill at both a flat source-of-truth path
  (`<target>/skills/<skill>.md`) and a Claude Code vendor-copy path
  (`.claude/skills/<eidolon>-<skill>/SKILL.md`) when the `claude-code` host is
  wired. The v1.2 §4.2.3 `MAY` for `.claude/skills/` is promoted to MUST for
  v1.3+ Eidolons.

v1.0-, v1.1-, and v1.2-conformant Eidolons remain conformant under v1.3
without modification. The new MUSTs bind **only** when an Eidolon declares
`EIIS_VERSION = 1.3` or later. This follows the same backward-compat pattern
used in v1.1 (Codex addendum) and v1.2 (ECL composition). See
[§6](#6--versioning--compatibility).

Future minor versions are additive. Breaking changes require a major version
bump and a migration guide. See [§6](#6--versioning--compatibility).

## Table of contents

- [§1 — Repo Layout](#1--repo-layout)
- [§1.8 — Canonical full-spec filename (v1.3+)](#18--canonical-full-spec-filename-v13)
- [§2 — `install.sh` flag contract](#2--installsh-flag-contract)
- [§3 — `install.manifest.json` schema](#3--installmanifestjson-schema)
- [§4 — Host wiring conventions](#4--host-wiring-conventions)
- [§4.2.3 — Per-skill auxiliary files (amended v1.3)](#423--per-skill-auxiliary-files-amended-v13)
- [§4.2.4 — Skills dual-write (v1.3+)](#424--skills-dual-write-v13)
- [§4.5 — Codex subagent contract (v1.1+)](#45--codex-subagent-contract-v11)
- [§4.6 — ECL composition (v1.2+)](#46--ecl-composition-v12)
- [§5 — Idempotency requirements](#5--idempotency-requirements)
- [§6 — Versioning & compatibility](#6--versioning--compatibility)
- [§7 — Non-goals](#7--non-goals)
- [Citations](#citations)
- [Appendix A — `wire_skill` reference implementation](#appendix-a--wire_skill-reference-implementation)
- [Appendix B — Changes from v1.2](#appendix-b--changes-from-v12)

---

## §1 — Repo Layout

A conformant Eidolon repository **MUST** contain at minimum, all at the
repository root:

| Path | Purpose | Stability |
|---|---|---|
| `agent.md` | Always-loaded entry-point document. SHOULD fit within an estimated 1000-token budget. | [Stable] |
| `AGENTS.md` | Vendor-neutral methodology summary. | [Stable] |
| `CLAUDE.md` | Claude Code surface document. | [Stable] |
| `README.md` | Human-readable repo introduction. | [Stable] |
| `install.sh` | Executable installer script (`bash`, with the executable bit set). | [Stable] |
| `EIIS_VERSION` | Single-line file containing a bare SemVer string declaring which EIIS minor the repo targets (e.g. `1.3`). | [Stable] |

§1.1 — **MUST**: each of the six paths above exists at the repository
root.

§1.2 — **MUST**: `install.sh` is executable (`chmod +x install.sh` or
runnable via `bash install.sh`).

§1.3 — **MUST**: `EIIS_VERSION` contains exactly one line matching the
regular expression `^[0-9]+\.[0-9]+(\.[0-9]+)?$`. Trailing newline
permitted. The first two components (MAJOR and MINOR) declare the
spec version this repo targets.

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
prohibit extension.

§1.7 — **MUST NOT**: introduce paths whose names collide with
EIIS-reserved names listed in the table above with semantics that differ
from this section.

---

## §1.8 — Canonical full-spec filename (v1.3+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.3` or later. v1.0, v1.1, and v1.2 Eidolons are unaffected.

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

§1.8.5 — **Compliance grade**: warn-only through 2027-04-24 for Eidolons that
declare `EIIS_VERSION = 1.0`, `1.1`, or `1.2`; MUST-fail for Eidolons
declaring `EIIS_VERSION = 1.3` or later.

---

## §2 — `install.sh` flag contract

`install.sh` is invoked by humans (directly) and by meta-installers (the
nexus). The contract below is what both audiences rely on.

§2.1 — **MUST** flags. `install.sh` MUST accept the following flags:

| Flag | Argument | Semantics |
|---|---|---|
| `--target DIR` | path | Where to install. Default: `./.eidolons/<EIDOLON_NAME>`. |
| `--hosts LIST` | comma-csv | Hosts to wire. Valid v1.0 values: `claude-code`, `copilot`, `cursor`, `opencode`, `all`, `auto`, `none`. |
| `--force` | none | Overwrite without prompting. |
| `--non-interactive` | none | Fail on any prompt. |
| `--dry-run` | none | Print actions without writing files. |
| `--version` | none | Print the Eidolon's SemVer to stdout and exit `0`. |
| `-h`, `--help` | none | Print usage to stdout and exit `0`. |

§2.2 — **SHOULD** flags. `install.sh` SHOULD accept:

| Flag | Argument | Semantics |
|---|---|---|
| `--shared-dispatch` | none | Compose marker-bounded blocks in root `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`. (See [§4.1](#41--marker-bounded-sections-shared-dispatch).) |
| `--no-shared-dispatch` | none | Skip composition. |
| `--manifest-only` | none | Emit `install.manifest.json` without copying methodology files. |

§2.3 — **Grandfather clause** for `--shared-dispatch` /
`--no-shared-dispatch` (drift D-1): SHOULD in v1.0 and v1.1; promoted to
**MUST** in v1.2 (target date 2027-04-24). Meta-installers MUST tolerate
installers that do not yet support these flags by detecting their
presence (e.g. `grep -q -- '--no-shared-dispatch' install.sh`) before
forwarding them.

§2.4 — **Exit codes** (normative):

| Code | Meaning |
|---|---|
| `0` | Success or graceful no-op. |
| `2` | Invalid argument (unknown flag, missing required argument, invalid `--hosts` value). |
| `3` | Already installed; `--non-interactive` set; `--force` not set. |
| `4` | `agent.md` exceeds the 1000-token budget under `--non-interactive` (SHOULD-grade enforcement). |

§2.5 — **MUST**: `--version` writes to stdout and exits `0` without
performing any file system mutation.

§2.6 — **MUST**: `-h` and `--help` write usage information to stdout and
exit `0` without performing any file system mutation.

§2.7 — **MUST**: an unknown flag produces a diagnostic on stderr and
exits `2`.

§2.8 — **MAY**: Eidolon-specific extensions (for example, VIGIL's
`--mode read-only|sandbox|write`). Extensions **MUST NOT** conflict with
the flag names reserved in §2.1, §2.2, and the host list values in §2.1.

§2.9 — **MUST NOT**: `install.sh` makes network calls (no `curl`, `wget`,
`git clone`, etc.). All inputs MUST come from the cloned Eidolon repo
itself or the consumer project's working tree.

---

## §3 — `install.manifest.json` schema

After a successful install (when `--manifest-only` is false or true),
`install.sh` **MUST** write `install.manifest.json` at
`<target>/install.manifest.json`. The schema is published at
[`schemas/install.manifest.v1.json`](../schemas/install.manifest.v1.json)
as a JSON Schema draft-2020-12 document.

§3.1 — **MUST**: the manifest is a JSON object with these required
fields:

```json
{
  "eidolon":      "string, lowercase slug, ^[a-z][a-z0-9-]*$",
  "version":      "string, SemVer ^\\d+\\.\\d+\\.\\d+$",
  "methodology":  "string",
  "installed_at": "string, RFC 3339 / ISO 8601 UTC timestamp",
  "target":       "string, relative path to install dir",
  "hosts_wired":  "array<enum>",
  "files_written": "array<object>"
}
```

§3.2 — **`hosts_wired` enum** (v1.1): `claude-code`, `copilot`, `cursor`,
`opencode`, `codex`, `raw`. v1.0 omitted `codex`; v1.1 adds it
additively (a v1.0-only manifest remains valid).

§3.3 — **`files_written` shape**: each entry is an object with these
fields:

| Field | Required | Type | Notes |
|---|---|---|---|
| `path` | yes | string | Path of the written file, relative to consumer repo root. |
| `sha256` | yes | string | SHA-256 hex digest of the file content after writing. |
| `role` | yes | enum | One of `entry-point`, `spec`, `skill`, `template`, `dispatch`, `manifest`, `other`. |
| `mode` | no | enum | One of `created`, `appended`, `overwritten`. |

§3.4 — **MUST**: `files_written` is populated when `--manifest-only` is
false. The empty array `[]` is a violation.

§3.5 — **`installed_at`** is the ONLY non-deterministic field. Every
other required field MUST be content-determined for a given (Eidolon
repo state, target dir, host list) tuple. See [§5](#5--idempotency-requirements).

§3.6 — **`version` override**: a meta-installer (such as the Eidolons
nexus) MAY rewrite the `version` field after the installer runs to
reflect the canonical upstream tag. This codifies drift D-5. Per-Eidolon
installers MUST tolerate post-write modification of this field. v2.0
deprecates the override path in favour of an `EIIS_VERSION`-style single
source of truth.

§3.7 — **Optional fields**:

| Field | Type | Notes |
|---|---|---|
| `handoffs_declared` | object | `{upstream: string[], downstream: string[]}`. |
| `token_budget` | object | `{entry: integer, working_set_target: integer}`. |
| `security` | object | `{reads_repo: bool, reads_network: bool, writes_repo: bool, persists: string[]}`. |
| `ecl_version_emitted` | string | The ECL spec version this Eidolon targets when emitting inter-Eidolon artefacts. If present, MUST match the value in the repo-root `ECL_VERSION` file (see [§4.6.4](#46--ecl-composition-v12)). |
| `spec_file` | string | Canonical full-spec path (v1.3+). MUST point at the `SPEC.md` emitted by this install. SHOULD be present from v1.3; conformance-required at `EIIS_VERSION ≥ 1.3`. Pattern: `^\.eidolons/[a-z][a-z0-9-]*/SPEC\.md$`. |
| `skills` | array | Skills emitted by this install, with source-of-truth and vendor paths (v1.3+). See §3.8. |

§3.8 — **`skills` array shape** (v1.3+, optional at schema level;
conformance-required at `EIIS_VERSION ≥ 1.3` when skills are present):

Each entry in `skills` is an object with these fields:

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | yes | string | Skill slug, `^[a-z][a-z0-9-]*$`. E.g. `planning`. |
| `source_path` | yes | string | Flat source-of-truth path: `^\.eidolons/[a-z][a-z0-9-]*/skills/[a-z][a-z0-9-]*\.md$`. |
| `source_sha256` | yes | string | SHA-256 of the source-of-truth file, `^[0-9a-fA-F]{64}$`. |
| `vendor_path` | no | string | Claude Code host vendor copy path. Present when `claude-code` is in `hosts_wired`. Pattern: `^\.claude/skills/[a-z][a-z0-9-]*-[a-z][a-z0-9-]*/SKILL\.md$`. |
| `vendor_sha256` | no | string | SHA-256 of the vendor copy. MUST equal `source_sha256` when present. |

§3.9 — **MUST**: the manifest is valid JSON parseable by `jq empty`.

§3.10 — **MUST NOT**: the manifest contains fields not listed in §3.1
(required) or §3.7 (optional) unless the Eidolon also declares
`EIIS_VERSION` for a future version that adds the field.

---

## §4 — Host wiring conventions

EIIS defines two surfaces for wiring an Eidolon into a consumer
project's host environment.

### §4.1 — Marker-bounded sections (shared dispatch)

Used in: root `AGENTS.md`, root `CLAUDE.md`, root
`.github/copilot-instructions.md`. When `--shared-dispatch` is true (and
once the flag becomes MUST in v1.2, in all installs that touch these
files), each Eidolon **MUST** own a marker-bounded region.

§4.1.0 — **Co-ownership of `AGENTS.md`** (clarified in v1.1). Root
`AGENTS.md` is the canonical project-instruction file for **both**
`copilot` and `codex`. Per the cross-vendor `agents.md` convention and
OpenAI's Codex documentation
(<https://developers.openai.com/codex/guides/agents-md>), Codex reads
`AGENTS.md` from the repo root. EIIS therefore treats writes to
`AGENTS.md` as a `codex`-and-`copilot`-shared surface: an installer
wiring either host (or both) writes the marker-bounded block exactly
once into root `AGENTS.md`. The marker convention below applies
unchanged.

```
<!-- eidolon:<name> start -->
…content…
<!-- eidolon:<name> end -->
```

§4.1.1 — **MUST**: `<name>` matches the lowercase slug in the manifest's
`eidolon` field.

§4.1.2 — **MUST**: the block is idempotent. A re-run produces
byte-identical output between the start and end markers (resolves drift
D-4). Reference implementation: ATLAS's `upsert_eidolon_block` in
`Rynaro/ATLAS/install.sh` — read-rewrite-or-append-or-create.

§4.1.3 — **MUST NOT**: write into these files outside a marker block.
Bare appends without markers (drift D-4) are a hard fail from v1.0.

### §4.2 — Per-host dispatch files (filename namespace)

Filename **is** the namespace. One file per Eidolon, one Eidolon per
file. No in-file markers required.

| Host | Path |
|---|---|
| `claude-code` | `.claude/agents/<name>.md` |
| `copilot` | `.github/instructions/<name>.instructions.md` |
| `cursor` | `.cursor/rules/<name>.mdc` |
| `opencode` | `.opencode/agents/<name>.md` |
| `codex` | `.codex/agents/<name>.md` (see also [§4.5](#45--codex-subagent-contract-v11)) |

§4.2.1 — **MUST**: `<name>` matches the lowercase slug in the manifest's
`eidolon` field.

§4.2.2 — **MUST**: each Eidolon owns at most one file per host directory
(no fan-out into multiple files per host with the same Eidolon slug).

### §4.2.3 — Per-skill auxiliary files (amended v1.3)

The v1.2 text permitted an Eidolon to **MAY** emit per-skill auxiliary
files under `.claude/skills/<phase>/`. This is amended in v1.3 as
follows:

An Eidolon **MUST** emit per-skill files at
`.eidolons/<name>/skills/<skill>.md` (source-of-truth) and **MUST** emit
per-skill vendor copies at `.claude/skills/<eidolon>-<skill>/SKILL.md`
when `claude-code` is wired (v1.3+; see [§4.2.4](#424--skills-dual-write-v13)).
The legacy subdir layout (`skills/<phase>/SKILL.md`) permitted under
v1.2 §4.2.3 is **deprecated** for v1.3-conformant Eidolons.

Cursor/Codex/OpenCode vendor-copy paths remain **MAY** (out of scope for
v1.3). The v1.2 MAY clause for those hosts is preserved.

### §4.2.4 — Skills dual-write (v1.3+)

This section is **normative** and applies only to Eidolons that declare
`EIIS_VERSION = 1.3` or later.

§4.2.4.1 — **MUST**: an Eidolon that ships skill files installs each
skill at **both** of the following paths in the consumer project:

```
<target>/skills/<skill>.md            # source-of-truth (flat, per-file)
.claude/skills/<eidolon>-<skill>/SKILL.md   # host vendor copy (auto-loaded by Claude Code)
```

where `<target>` defaults to `./.eidolons/<EIDOLON_NAME>`, `<eidolon>` is
the lowercase slug (§3.1), and `<skill>` matches the regular expression
`^[a-z][a-z0-9-]*$`.

§4.2.4.2 — **MUST**: the two written files are byte-identical at the time
of write. The `source_sha256` and `vendor_sha256` in the `skills[]`
manifest entry (§3.8) MUST match.

§4.2.4.3 — **MUST**: the source-of-truth path uses a flat per-file layout
(`<skill>.md` directly under `skills/`). The `<skill>/SKILL.md` subdir
layout permitted under v1.2 §4.2.3 is **deprecated**; v1.3-conformant
Eidolons MUST use the flat layout for the source-of-truth path. The host
vendor copy continues to use `<eidolon>-<skill>/SKILL.md` as a subdir
(Claude Code's convention).

§4.2.4.4 — **MUST**: when `claude-code` is in `--hosts`, both writes
happen. When `claude-code` is NOT in `--hosts`, only the source-of-truth
write happens. The source-of-truth write is host-independent (it is part
of the methodology install, not host wiring).

§4.2.4.5 — **MUST**: each skill produces two `files_written[]` entries,
distinguishable by `path`. Both entries carry `role: "skill"`.

§4.2.4.6 — **Compliance grade**: warn-only through 2027-04-24 for
`EIIS_VERSION ≤ 1.2`; MUST-fail for `EIIS_VERSION ≥ 1.3`.

---

## §4.5 — Codex subagent contract (v1.1+)

This section is **normative** and applies only to Eidolons that wire
the `codex` host. v1.0-only Eidolons (those whose `EIIS_VERSION` is
`1.0` and whose installer does not handle `--hosts codex`) are
unaffected.

### §4.5.1 — File path

§4.5.1.1 — **MUST**: a Codex-aware installer, when invoked with a host
list containing `codex`, writes exactly one Markdown file at:

```
.codex/agents/<name>.md
```

relative to the consumer project root, where `<name>` matches the
lowercase slug in the manifest's `eidolon` field (§3.1, §4.2.1).

§4.5.1.2 — **MUST NOT**: an Eidolon write more than one file under
`.codex/agents/` for the same Eidolon slug. Per-skill auxiliary files
under `.codex/agents/<eidolon>-<phase>.md` are **MAY** (parallel to
§4.2.3) and are namespaced by their full filename — they are not
Codex *subagents* in the sense of this section.

§4.5.1.3 — **MUST NOT**: an installer write to nested `AGENTS.md`
files outside the repo root, nor to `.codex/` paths other than
`.codex/agents/<name>.md` (and §4.5.1.2 auxiliaries). The directory
itself MAY be created if missing.

### §4.5.2 — Frontmatter

§4.5.2.1 — **MUST**: the file begins with a YAML frontmatter block
delimited by `---` lines, exactly as documented in OpenAI's Codex
subagents reference (<https://developers.openai.com/codex/subagents>):

```yaml
---
name: <slug>
description: <one-line summary>
---
```

§4.5.2.2 — **Required fields**:

| Key | Type | Notes |
|---|---|---|
| `name` | string | MUST equal the manifest `eidolon` slug. Lowercase, `^[a-z][a-z0-9-]*$`. |
| `description` | string | MUST be non-empty. Surfaced to the parent Codex agent for routing. |

§4.5.2.3 — **Optional fields**:

| Key | Type | Notes |
|---|---|---|
| `tools` | array of string | Restricted tool allowlist. Omit to inherit the parent agent's tools. |
| `model` | string | Override the model used by the subagent. Omit to inherit. |

§4.5.2.4 — **MUST**: the frontmatter parses as valid YAML. EIIS does
not constrain field ordering, but RECOMMENDS `name` first, then
`description`, then optional fields in declaration order.

§4.5.2.5 — **MAY**: vendor-specific fields beyond `name`, `description`,
`tools`, `model`, if and when OpenAI documents them. Future EIIS minors
MAY codify additional REQUIRED fields; until then, additional keys are
tolerated.

### §4.5.3 — Body

§4.5.3.1 — **SHOULD**: the body beneath the frontmatter contains the
Eidolon's system prompt or methodology pointer, written as Markdown.

§4.5.3.2 — **SHOULD**: the body cites
`./.eidolons/<name>/agent.md` (or the `--target` equivalent) as the
canonical methodology entry point, so a Codex subagent invocation
resolves to the same pipeline a Claude Code subagent invocation does.

§4.5.3.3 — **MAY**: the body diverge from the corresponding
`.claude/agents/<name>.md` content. EIIS enforces structural
conformance only — valid frontmatter and correct file path. Content
equivalence between hosts is **NOT** a conformance requirement.
Maintainers are encouraged but not required to mirror.

### §4.5.4 — Idempotency

§4.5.4.1 — **MUST**: a second invocation of `bash install.sh
--hosts codex --force` against the same starting state produces a
byte-identical `.codex/agents/<name>.md` (subject to §5).

§4.5.4.2 — **MUST**: the marker-bounded block in root `AGENTS.md`
(§4.1) and the Codex subagent file (§4.5.1) are written
atomically with respect to each other from the user's perspective —
either both succeed or the installer exits non-zero before declaring
success. Partial state (one written, the other not) on a clean
invocation is a violation.

### §4.5.5 — Manifest record

§4.5.5.1 — **MUST**: when an installer writes the Codex subagent
file, `install.manifest.json` records `"codex"` in `hosts_wired`
(§3.2) and lists `.codex/agents/<name>.md` (and root `AGENTS.md`,
when written) under `files_written` (§3.3) with appropriate `role`
values (`dispatch` for both is acceptable).

### §4.5.6 — Filename collision (informative)

The combination of §4.5.1.1 (`<name>.md` filename equals the manifest
slug) and §3.1 (slug is unique per Eidolon) means filename collisions
across Eidolons are structurally impossible. A conformance checker
MAY warn if it observes two `.md` files in `.codex/agents/` declaring
the same `name:` value in their frontmatter — that is a packaging
bug, not a runtime concern.

---

## §4.6 — ECL composition (v1.2+)

This section is **normative** and applies only to Eidolons that emit
inter-Eidolon hand-off artefacts under the Eidolons Communication Layer
specification (`Rynaro/eidolons-ecl`). v1.0- and v1.1-conformant Eidolons
that do not emit ECL artefacts are completely unaffected by this section.

ECL and EIIS are **sibling standards** — ECL governs the wire format and
hand-off contract for runtime inter-Eidolon communication; EIIS governs the
install contract. They compose but do not overlap.

### §4.6.1 — `ECL_VERSION` file (MAY)

§4.6.1.1 — **MAY**: an Eidolon repo MAY contain a top-level `ECL_VERSION`
file at the repository root. When present, the file MUST contain exactly
one line matching the regular expression `^[0-9]+\.[0-9]+(\.[0-9]+)?$`.
A trailing newline is permitted but not required.

§4.6.1.2 — The value declares the ECL spec version this Eidolon targets
when emitting inter-Eidolon artefacts.

§4.6.1.3 — An Eidolon that does **not** emit ECL artefacts SHOULD NOT
ship `ECL_VERSION`.

### §4.6.2 — ECL conformance when `ECL_VERSION` is present (MUST)

§4.6.2.1 — **MUST**: if `ECL_VERSION` is present, an Eidolon that emits
ECL envelopes MUST satisfy the corresponding ECL spec version. ECL
conformance is verified separately by the ECL checker
(`Rynaro/eidolons-ecl/conformance/check.sh`).

### §4.6.3 — Prohibition on ECL emission without declaration (MUST NOT)

§4.6.3.1 — **MUST NOT**: an Eidolon SHALL NOT emit ECL envelopes without
declaring `ECL_VERSION` at the repository root.

### §4.6.4 — `ecl_version_emitted` manifest field (MAY)

§4.6.4.1 — **MAY**: the `install.manifest.json` MAY include an
`ecl_version_emitted` string field (listed in §3.7). When present, its
value MUST match the content of the repo-root `ECL_VERSION` file exactly.

§4.6.4.2 — A mismatch between `ecl_version_emitted` and `ECL_VERSION` is
a MUST-violation. The conformance checker emits a WARN for this case.

### §4.6.5 — Conformance checker behaviour (informative)

| Check ID | Level | Description |
|---|---|---|
| `E0` | MUST (warn-only) | `ECL_VERSION` format matches `^[0-9]+\.[0-9]+(\.[0-9]+)?$`. |
| `E1` | WARN | If `install.manifest.json` includes `ecl_version_emitted`, it matches `ECL_VERSION`. |

---

## §5 — Idempotency requirements

A second invocation of:

```
bash install.sh --target <T> --hosts <H> --force
```

against the same starting state **MUST** produce:

§5.1 — **MUST**: byte-identical files in `<T>/`, EXCEPT for the
`installed_at` field of `<T>/install.manifest.json`.

§5.2 — **MUST**: byte-identical marker blocks in shared-dispatch files
(see §4.1).

§5.3 — **MUST**: byte-identical per-host dispatch files (see §4.2).

§5.4 — **Recommended verification** (informative):

```
find <T> -type f | sort | xargs sha256sum > before.sums
bash install.sh --target <T> --hosts <H> --force
find <T> -type f | sort | xargs sha256sum > after.sums
diff before.sums after.sums   # only install.manifest.json may differ
```

---

## §6 — Versioning & compatibility

§6.1 — **EIIS** uses [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html):

| Bump | Trigger |
|---|---|
| **MAJOR** | Breaking change to any MUST. Migration guide REQUIRED. Each shipped Eidolon must opt in by updating `EIIS_VERSION`. |
| **MINOR** | Additive change: new host enum value, new optional manifest field, new SHOULD. Backward-compatible. |
| **PATCH** | Clarification only; no semantic change. |

§6.2 — **Eidolon ↔ EIIS relationship**:

- An Eidolon at `EIIS_VERSION 1.0` MUST satisfy v1.0's MUSTs.
- An Eidolon MAY declare `EIIS_VERSION 1.1` and use v1.1 features.
- An Eidolon MAY declare `EIIS_VERSION 1.2` and use v1.2 features.
- An Eidolon MAY declare `EIIS_VERSION 1.3` and use v1.3 features
  (§1.8 canonical spec filename, §4.2.4 skills dual-write). The nexus
  consuming such an Eidolon MUST tolerate v1.0/v1.1/v1.2 manifests as
  well — `eiis_required` in the nexus roster declares the **minimum**
  EIIS version supported, not a pinned one.

§6.2.1 — **v1.0/v1.1/v1.2/v1.3 backward compatibility**: v1.0-, v1.1-,
and v1.2-conformant Eidolons pass v1.3 conformance unchanged. The new
MUSTs (§1.8, §4.2.4) bind only when an Eidolon declares
`EIIS_VERSION = 1.3`. Eidolons that have not yet migrated stay at their
current `EIIS_VERSION` and pass the conformance checker on their pinned
codepath.

§6.3 — **Promotion timeline** for warn-only fields:

| Field | v1.0 | v1.1 | v1.2 | v1.3 |
|---|---|---|---|---|
| `EIIS_VERSION` file (D-6) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail |
| `files_written` populated (D-3) | MUST, warn-only | MUST, warn-only | MUST, fail | MUST, fail |
| `--shared-dispatch` flag (D-1) | SHOULD | SHOULD | MUST | MUST |
| Marker convention (D-4) | MUST, fail | MUST, fail | MUST, fail | MUST, fail |
| `ECL_VERSION` format (E0) | n/a | n/a | MUST, warn-only | MUST, warn-only |
| `ecl_version_emitted` ↔ `ECL_VERSION` (E1) | n/a | n/a | WARN | WARN |
| Spec filename = `SPEC.md` (S1) | n/a | n/a | n/a | MUST, fail |
| `spec_file` field present (S2) | n/a | n/a | n/a | MUST, fail |
| Skills flat source-of-truth (K1) | n/a | n/a | n/a | MUST, fail |
| Skills `vendor_sha256` = `source_sha256` (K2) | n/a | n/a | n/a | MUST, fail |
| Skills `vendor_path` on disk (K3) | n/a | n/a | n/a | WARN |

§6.4 — **Hard-fail promotion target date**: 2027-04-24.

§6.5 — `EIIS_VERSION` file format: a single line, bare SemVer
(`<MAJOR>.<MINOR>` or `<MAJOR>.<MINOR>.<PATCH>`). No `v` prefix, no
suffix. A trailing newline is permitted but not required.

---

## §7 — Non-goals

EIIS does **NOT** mandate, define, or constrain:

- The methodology content of any Eidolon.
- The runtime behaviour of an installed Eidolon.
- Vendor host APIs, frontmatter schemas, or invocation patterns.
- Working-set token budgets, other than the 1000-token `agent.md` SHOULD.
- Persistence locations on disk, other than `<target>/`.
- Network behaviour. Installers MUST NOT make network calls (§2.9).
- The `eidolons.yaml` / `eidolons.lock` schemas (nexus-owned).
- The contents of `ECL_VERSION` or any ECL semantics beyond the file's
  presence and format.
- Vendor-copy paths for Cursor (`.cursor/rules/`), Codex
  (`.codex/agents/`), or OpenCode (`.opencode/agents/`) when used as
  per-skill vendor copies. Those remain MAY in v1.3.
- A shared `wire_skill` library function across repos. Each Eidolon's
  `install.sh` is self-contained (see Appendix A for a reference
  implementation to copy-paste).

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
8. Codex agents.md. <https://developers.openai.com/codex/guides/agents-md>
9. Codex subagents. <https://developers.openai.com/codex/subagents>
10. ECL — Eidolons Communication Layer v1.0.
    <https://github.com/Rynaro/eidolons-ecl>

### Drift register cross-reference

This spec resolves the following drifts identified in the
`Rynaro/eidolons/docs/specs/eiis-bootstrap/SPEC.md` design document:

| Drift | Resolution location |
|---|---|
| **D-1** — `--shared-dispatch` flag | §2.3 (SHOULD with grandfather clause) |
| **D-2** — `codex` enum | resolved in v1.1: §3.2 (`hosts_wired`), §4.2, §4.5 |
| **D-3** — `files_written` populated | §3.4 (MUST, fail) |
| **D-4** — Marker convention | §4.1.2, §4.1.3 (MUST, fail from v1.0) |
| **D-5** — Installer version source-of-truth | §3.6 (codified; deprecated in v2.0) |
| **D-6** — `EIIS_VERSION` file | §1.1, §1.3 (MUST, fail) |
| **D-7** — Required file set | §1 (expanded; conformance checker validates fully) |

---

## Appendix A — `wire_skill` reference implementation

The following bash function is the canonical reference implementation for
the skills dual-write pattern (§4.2.4). **This is non-normative** — EIIS
does not mandate this exact function signature. Per §7, no shared
library is introduced; copy-paste this snippet into each Eidolon's
`install.sh`.

Bash 3.2 compatible (no `declare -A`, no `${var,,}`, no `readarray`,
no `&>>`).

```bash
# wire_skill <skill_name>
#
# Dual-writes a skill file per EIIS v1.3 §4.2.4:
#   - source-of-truth: ${TARGET}/skills/<skill_name>.md
#   - vendor copy:     .claude/skills/${EIDOLON_SLUG}-<skill_name>/SKILL.md
#
# Source file resolved as: ${SCRIPT_DIR}/skills/<skill_name>.md
#
# Records both files in the manifest via copy_tracked / add_fw helpers.
# Caller is responsible for ensuring EIDOLON_SLUG, TARGET, SCRIPT_DIR are
# set and that copy_tracked / add_fw helpers exist.
wire_skill() {
  local skill="$1"
  local src="${SCRIPT_DIR}/skills/${skill}.md"
  local dst_src="${TARGET}/skills/${skill}.md"
  local dst_vendor=".claude/skills/${EIDOLON_SLUG}-${skill}/SKILL.md"

  if [ ! -f "${src}" ]; then
    echo "ERROR: skill source not found: ${src}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${dst_src}")"
  mkdir -p "$(dirname "${dst_vendor}")"

  copy_tracked "${src}" "${dst_src}" "skill"

  if printf '%s\n' "${HOSTS_WIRED}" | grep -q 'claude-code'; then
    copy_tracked "${src}" "${dst_vendor}" "skill"
  fi
}
```

**Compat notes:**
- `printf '%s\n' "${HOSTS_WIRED}" | grep -q 'claude-code'` — bash 3.2
  safe. Do NOT use `[[ ${HOSTS_WIRED[@]} =~ claude-code ]]` (bash 4+).
- `local` inside functions — fine in bash 3.2.
- `HOSTS_WIRED` should be a space-separated or comma-separated string;
  adjust the `grep` pattern to match your installer's convention.

---

## Appendix B — Changes from v1.2

### New normative sections

| Section | Summary |
|---|---|
| §1.8 | Canonical full-spec filename: MUST write `<target>/SPEC.md`. |
| §4.2.3 (amended) | Skills dual-write promoted from MAY to MUST for v1.3+ when `claude-code` is wired. |
| §4.2.4 | Skills dual-write: flat source-of-truth + Claude Code vendor copy. |

### Schema additions (additive; no breaking changes)

| Field | Location | Notes |
|---|---|---|
| `spec_file` | `properties` top-level optional | Canonical spec path pointer. Pattern `^\.eidolons/[a-z][a-z0-9-]*/SPEC\.md$`. |
| `skills` | `properties` top-level optional array | Per-skill dual-write record (name, source_path, source_sha256, vendor_path, vendor_sha256). |

### Conformance checker additions

| Check ID | Level | Binding from |
|---|---|---|
| S1 | MUST (warn ≤ 1.2; fail ≥ 1.3) | The single `role: "spec"` entry has basename `SPEC.md`. |
| S2 | MUST (fail ≥ 1.3) | `spec_file` field present and matches the `role: "spec"` entry's path. |
| K1 | MUST (warn ≤ 1.2; fail ≥ 1.3) | If `skills` present, each `source_path` matches the flat layout pattern. |
| K2 | MUST (warn ≤ 1.2; fail ≥ 1.3) | If `vendor_sha256` present, it equals `source_sha256`. |
| K3 | WARN | If `claude-code` in `hosts_wired` and skills exist, `vendor_path` is present. |

### Backward compatibility

v1.0-, v1.1-, and v1.2-conformant Eidolons pass v1.3 conformance
without any modification. The new MUSTs (§1.8 and §4.2.4) bind only
when `EIIS_VERSION ≥ 1.3`. Migration is opt-in: each Eidolon bumps its
own `EIIS_VERSION` in the same PR that renames the spec file and adds
the skills dual-write.
