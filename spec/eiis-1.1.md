# EIIS — Eidolons Individual Install Standard

**Version:** 1.1
**Status:** Stable
**Published:** 2026-04-25
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

This is EIIS v1.1, an additive minor release over v1.0. v1.1 introduces
**OpenAI Codex** as a recognised host (`codex`), formalises the per-Eidolon
**Codex subagent contract** under `.codex/agents/<name>.md`, and clarifies
that root `AGENTS.md` is co-owned by the `copilot` and `codex` hosts under
the existing marker convention.

v1.0-conformant Eidolons remain conformant under v1.1 without modification.
The Codex surface is **OPTIONAL** — an Eidolon MAY ship Codex artefacts
(`hosts_wired` containing `codex`, a `.codex/agents/<name>.md` file) but is
not required to. Eidolons that do ship the Codex surface MUST satisfy the
contract in [§4.5](#45--codex-subagent-contract-v11).

Future minor versions are additive. Breaking changes require a major
version bump and a migration guide. See [§6](#6--versioning--compatibility).

## Table of contents

- [§1 — Repo Layout](#1--repo-layout)
- [§2 — `install.sh` flag contract](#2--installsh-flag-contract)
- [§3 — `install.manifest.json` schema](#3--installmanifestjson-schema)
- [§4 — Host wiring conventions](#4--host-wiring-conventions)
- [§4.5 — Codex subagent contract (v1.1+)](#45--codex-subagent-contract-v11)
- [§5 — Idempotency requirements](#5--idempotency-requirements)
- [§6 — Versioning & compatibility](#6--versioning--compatibility)
- [§7 — Non-goals](#7--non-goals)
- [Citations](#citations)

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
| `EIIS_VERSION` | Single-line file containing a bare SemVer string declaring which EIIS minor the repo targets (e.g. `1.0`). | [Stable] (resolves drift D-6) |

§1.1 — **MUST**: each of the six paths above exists at the repository
root.

§1.2 — **MUST**: `install.sh` is executable (`chmod +x install.sh` or
runnable via `bash install.sh`).

§1.3 — **MUST**: `EIIS_VERSION` contains exactly one line matching the
regular expression `^[0-9]+\.[0-9]+(\.[0-9]+)?$`. Trailing newline
permitted. The first two components (MAJOR and MINOR) declare the
spec version this repo targets. Compliance for v1.0 is **warn-only**
through 2027-04-24 (drift D-6).

§1.4 — **SHOULD**: a `CHANGELOG.md` in [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/) format.

§1.5 — **SHOULD**: a vendored copy of EIIS's manifest schema at
`schemas/install.manifest.v1.json` so installers can self-validate.

A conformant Eidolon repository **MAY** contain:

| Path | Purpose |
|---|---|
| `skills/<phase>/SKILL.md` | Progressive-disclosure skill files. |
| `templates/<artifact>.md` | Output skeletons. |
| `evals/` | Canary missions or scenario tests. |
| `LICENSE` | Per-repo licence (RECOMMENDED). |

§1.6 — **MAY**: any additional Eidolon-specific files. EIIS does not
prohibit extension.

§1.7 — **MUST NOT**: introduce paths whose names collide with
EIIS-reserved names listed in the table above with semantics that differ
from this section.

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
false. The empty array `[]` is a violation. Compliance for v1.0 is
**warn-only** through 2027-04-24 (drift D-3); promoted to MUST-fail in
v1.2.

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

§3.8 — **MUST**: the manifest is valid JSON parseable by `jq empty`.

§3.9 — **MUST NOT**: the manifest contains fields not listed in §3.1
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
Bare appends without markers (drift D-4 — FORGE today) are a hard fail
from v1.0.

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

§4.2.3 — **MAY**: an Eidolon emit per-skill auxiliary files under
`.claude/skills/<phase>/`, `.github/instructions/<eidolon>-<phase>.instructions.md`,
or `.cursor/rules/<eidolon>-<phase>.mdc`. These are not Eidolon dispatch
files in the sense of §4.2 and do not need to be unique by Eidolon
slug — they are namespaced by their full filename.

### §4.3 — Vendor frontmatter pointers (informative)

EIIS does **not** copy or duplicate vendor schemas. Each host's
frontmatter (e.g. Cursor's `description`/`globs`/`alwaysApply`, Codex's
`name`/`description`/`tools?`/`model?`) is defined by the vendor and may
evolve out of band. EIIS cites:

| Host | Vendor documentation |
|---|---|
| `claude-code` | Anthropic Claude Code subagents documentation |
| `copilot` | GitHub Copilot custom instructions documentation |
| `cursor` | Cursor Rules documentation |
| `opencode` | OpenCode agents documentation |
| `codex` | <https://developers.openai.com/codex/subagents>; <https://developers.openai.com/codex/guides/agents-md> |

This subsection is **informative**, not normative.

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

§5.5 — **Out of scope for v1.0**: a separate `INSTALL_STATE/` directory
or sidecar journal. Idempotency is achieved by content-derived markers
(§4.1) and the `files_written` array (§3.3), which doubles as a removal
map. v2.0 may revisit if `eidolons remove` reverse-lookup proves
insufficient in practice.

---

## §6 — Versioning & compatibility

§6.1 — **EIIS** uses [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html):

| Bump | Trigger |
|---|---|
| **MAJOR** | Breaking change to any MUST. Migration guide REQUIRED. Each shipped Eidolon must opt in by updating `EIIS_VERSION`. |
| **MINOR** | Additive change: new host enum value, new optional manifest field, new SHOULD. Backward-compatible. |
| **PATCH** | Clarification only; no semantic change. |

§6.2 — **Eidolon ↔ EIIS relationship**:

- An Eidolon at `EIIS_VERSION 1.0` MUST satisfy v1.0's MUSTs and SHOULD
  satisfy v1.0's SHOULDs.
- An Eidolon MAY declare `EIIS_VERSION 1.1` and use v1.1 features
  (e.g. `codex` in `hosts_wired`). The nexus consuming such an Eidolon
  MUST tolerate v1.0 manifests as well — `eiis_required` in the nexus
  roster declares the **minimum** EIIS version supported, not a pinned
  one.

§6.3 — **Promotion timeline** for warn-only fields:

| Field | v1.0 status | v1.1 status | v1.2 status |
|---|---|---|---|
| `EIIS_VERSION` file (D-6) | MUST, warn-only | MUST, warn-only | MUST, fail |
| `files_written` populated (D-3) | MUST, warn-only | MUST, warn-only | MUST, fail |
| `--shared-dispatch` flag (D-1) | SHOULD | SHOULD | MUST |
| Marker convention in shared-dispatch writes (D-4) | MUST, fail | MUST, fail | MUST, fail |

§6.4 — **Hard-fail promotion target date**: 2027-04-24 (12 months after
v1.0 publication). Each Eidolon and every third-party adopter receives a
full release cycle to comply.

§6.5 — `EIIS_VERSION` file format: a single line, bare SemVer
(`<MAJOR>.<MINOR>` or `<MAJOR>.<MINOR>.<PATCH>`). No `v` prefix, no
suffix. A trailing newline is permitted but not required.

---

## §7 — Non-goals

EIIS does **NOT** mandate, define, or constrain:

- The methodology content of any Eidolon. (`agent.md` semantics, P0
  rules, working-set strategies.)
- The runtime behaviour of an installed Eidolon.
- Vendor host APIs, frontmatter schemas, or invocation patterns. EIIS
  cites these in §4.3 as informative pointers only.
- Working-set token budgets, other than the 1000-token `agent.md` SHOULD
  inherited from the v1.0 reference installers.
- Persistence locations on disk, other than `<target>/`.
- Network behaviour. Installers MUST NOT make network calls (§2.9). The
  nexus is the only tier authorised to fetch.
- The `eidolons.yaml` / `eidolons.lock` schemas. Those are nexus-owned
  (`Rynaro/eidolons`).

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

### Drift register cross-reference

This spec resolves the following drifts identified in the
`Rynaro/eidolons/docs/specs/eiis-bootstrap/SPEC.md` design document:

| Drift | Resolution location |
|---|---|
| **D-1** — `--shared-dispatch` flag | §2.3 (SHOULD with grandfather clause) |
| **D-2** — `codex` enum | resolved in v1.1: §3.2 (`hosts_wired`), §4.2 (`.codex/agents/<name>.md`), §4.5 (subagent contract) |
| **D-3** — `files_written` populated | §3.4 (MUST, warn-only) |
| **D-4** — Marker convention | §4.1.2, §4.1.3 (MUST, fail from v1.0) |
| **D-5** — Installer version source-of-truth | §3.6 (codified; deprecated in v2.0) |
| **D-6** — `EIIS_VERSION` file | §1.1, §1.3 (MUST, warn-only) |
| **D-7** — Required file set | §1 (expanded; conformance checker validates fully) |
