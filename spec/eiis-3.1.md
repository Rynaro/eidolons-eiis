# EIIS — Eidolons Individual Install Standard

**Version:** 3.1.0
**Status:** Stable
**Published:** 2026-09-23
**License:** Apache-2.0

## 1. Purpose

EIIS 3.1 is an additive minor release over EIIS 3.0. Methodology content still
has exactly one authoritative installed location. Host-specific files discover
that content; they do not reproduce it. v3.1 makes the **nexus-owned Cursor
discovery surfaces** explicit so adapters stay portable across hosts.

The BCP 14 terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

## 2. Canonical repository layout

A v3 repository MUST contain `PERSONA.md`, `SPEC.md`, `manifest.json`,
`README.md`, executable `install.sh`, and `EIIS_VERSION` at its root. It MUST
NOT contain `agent.md` or `EIDOLONS.md`.

`PERSONA.md` is the bounded identity, triggers, authority, refusals, and
hand-off summary. `SPEC.md` is the normative methodology. Team routing belongs
only to the consumer repository's root `EIDOLONS.md` and is nexus-owned.

`AGENTS.md`, `CLAUDE.md`, and equivalent host documents MAY exist. Their
Eidolons-owned prose MUST refer to root `EIDOLONS.md`; it MUST NOT contain a
second persona, specification, or skill body.

## 3. Canonical consumer layout

An installed member MUST use:

```text
.eidolons/<agent>/
├── EIIS_VERSION
├── PERSONA.md
├── SPEC.md
├── manifest.json
├── install.receipt.json
└── skills/<methodology>/
    ├── SKILL.md
    └── <resources>
```

Each skill MUST be a directory with exactly one entrypoint named `SKILL.md`.
Skill-specific scripts, references, schemas, examples, and assets SHOULD be
colocated in that directory. Shared resources MAY live elsewhere below the
same `.eidolons/<agent>/` tree. A skill MUST NOT depend on an authoritative
methodology file outside its agent tree.

Root `EIDOLONS.md` MUST exist in the consumer repository. The legacy
`.eidolons/cortex/EIDOLONS.md` path MAY exist only as a relative symlink to
the root file.

## 4. Host discovery adapters

Host adapters contain discovery metadata only. A host-native pointer file
MUST name the canonical `PERSONA.md` and `SPEC.md` paths. When a host requires
its own `SKILL.md`, that file MUST be a relative symlink to the canonical
`.eidolons/<agent>/skills/<methodology>/SKILL.md`, or a constrained pointer
(≤ 2048 bytes, `generated_by: eidolons`, no in-file markers) when a symlink
cannot satisfy the host's frontmatter contract. A copied skill body is a
conformance failure even when its digest currently matches.

Adapters MUST be removable without modifying canonical content. Installers
MUST NOT rely on symlinks escaping the consumer repository.

### 4.1 Nexus-owned path templates (v3.1+)

Per `V3-A1`, packages remain adapter-free. When the nexus (or an equivalent
host-adapter renderer) emits discovery surfaces for a wired host, it MUST use
these path templates:

| Host | Surface | Path |
|---|---|---|
| `claude-code` | agents | `.claude/agents/<name>.md` |
| `claude-code` | skills | `.claude/skills/<name>-<skill>/SKILL.md` |
| `codex` | agents | `.codex/agents/<name>.toml` (or host-native equivalent) |
| `copilot` | agents | `.github/agents/<name>.agent.md` |
| `opencode` | agents | `.opencode/agents/<name>.md` |
| `cursor` | rules | `.cursor/rules/<name>.mdc` |
| `cursor` | agents | `.cursor/agents/<name>.md` |
| `cursor` | skills | `.cursor/skills/<name>-<skill>/SKILL.md` |

`<name>` MUST match the package slug. Cursor Skills frontmatter `name` MUST
equal the folder basename (`<name>-<skill>`). Cursor agents MAY set
`readonly: true` when the member's capability class is scout / read-only.

Emitting only `.cursor/rules/<name>.mdc` without agents/skills is permitted
for legacy consumers; a v3.1-aware nexus adapter pass SHOULD emit all three
Cursor surfaces when `cursor` is wired.

## 5. Package manifest and installation receipt

`manifest.json` is immutable package metadata governed by
`schemas/package-manifest.v3.json`. It declares the persona, specification,
skill entrypoints, package resources, hooks, and security posture. Resources
below a declared skill directory are transitively owned; they are not repeated
in the package-level inventory. Other runtime files or directories, such as
commands, schemas, templates, contracts, and binaries, MUST be named once in
the top-level `resources` array and installed at the same relative path.

`install.receipt.json` is generated consumer state governed by
`schemas/install-receipt.v1.json`. It records the package identity and digest,
installed tree digest, target, timestamp, and disposable host adapters.
Package metadata MUST NOT contain installation timestamps or host wiring.

## 6. Hooks and harness verification

The v1.5 hook role and `hook_event` rules remain in force. Presence alone is
not proof of loading: a harness MUST verify executable permission, syntax,
and registration in the host configuration. Hook runtime failures remain
fail-open unless a separately declared enforcement hook intentionally blocks.

## 7. Compatibility

EIIS 1.x remains checkable without modification. EIIS 3.0 is a breaking
authoring contract: a repository opts in by writing `3.0.0` (or later 3.x) to
`EIIS_VERSION`. There is no 2.x line. This deliberate major jump prevents a
repository from claiming both the v1 duplicated-skill layout and the v3
single-source layout.

EIIS 3.1 is additive: packages that declare `EIIS_VERSION = 3.0.0` remain
conformant. The §4.1 path templates bind nexus adapter renderers; they do not
require packages to emit host-vendor files.

## 8. Conformance gates

- `V3-P1`: canonical package files exist and legacy package entrypoints are absent.
- `V3-M1`: `manifest.json` validates and binds the canonical persona/spec pair.
- `V3-S1`: source skills use `skills/<methodology>/SKILL.md`.
- `V3-R1`: declared resources remain inside the package tree.
- `V3-H1`: declared hooks are executable and use supported events.
- `V3-A1`: the package is adapter-free; the nexus owns host discovery.
- `V3-A2`: when nexus-emitted Cursor adapters are present, they use the §4.1
  path templates and satisfy the pointer/symlink contract (v3.1+).
- `V3-I1`: installation emits a valid receipt for the installed package.
- `V3-I2`: repeated installation is byte-idempotent.

All v3 gates are MUST-fail from publication; there is no warning window for
repositories that explicitly declare the new major version. `V3-A2` is
presence-gated (skipped when no Cursor vendor adapters exist).
