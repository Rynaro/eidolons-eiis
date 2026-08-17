# EIIS — Eidolons Individual Install Standard

**Version:** 3.0.0
**Status:** Stable
**Published:** 2026-08-17
**License:** Apache-2.0

## 1. Purpose

EIIS 3.0 makes every Eidolon self-contained. Methodology content has exactly
one authoritative installed location. Host-specific files discover that
content; they do not reproduce it.

The BCP 14 terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

## 2. Canonical repository layout

A v3 repository MUST contain `EIDOLONS.md`, `PERSONA.md`, `SPEC.md`,
`README.md`, executable `install.sh`, and `EIIS_VERSION` at its root. It MUST
NOT contain `agent.md`.

`EIDOLONS.md` is the routing and composition entrypoint. `PERSONA.md` is the
bounded identity, triggers, authority, refusals, and hand-off summary.
`SPEC.md` is the normative methodology.

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
├── install.manifest.json
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
`.eidolons/<agent>/skills/<methodology>/SKILL.md`. A copied skill body is a
conformance failure even when its digest currently matches.

Adapters MUST be removable without modifying canonical content. Installers
MUST NOT rely on symlinks escaping the consumer repository.

## 5. Manifest contract

The install manifest MUST contain `eiis_version`, `persona_file`, `spec_file`,
and exactly one `files_written` entry with role `persona` and one with role
`spec`. Every installed regular file and every adapter MUST be inventory
tracked. Each skill entry MUST use a canonical `/SKILL.md` `source_path` and
MUST declare `adapter_type` when a vendor adapter exists. Resources SHOULD be
listed in the skill's `resources` array.

## 6. Hooks and harness verification

The v1.5 hook role and `hook_event` rules remain in force. Presence alone is
not proof of loading: a harness MUST verify executable permission, syntax,
and registration in the host configuration. Hook runtime failures remain
fail-open unless a separately declared enforcement hook intentionally blocks.

## 7. Compatibility

EIIS 1.x remains checkable without modification. EIIS 3.0 is a breaking
authoring contract: a repository opts in by writing `3.0.0` to `EIIS_VERSION`.
There is no 2.x line. This deliberate major jump prevents a repository from
claiming both the v1 duplicated-skill layout and the v3 single-source layout.

## 8. Conformance gates

- `V3-L1`: canonical source files exist and `agent.md` is absent.
- `V3-L2`: root host documents refer to `EIDOLONS.md`.
- `V3-S1`: source skills use `skills/<methodology>/SKILL.md`.
- `V3-M1`: manifest binds v3 and the canonical persona/spec pair.
- `V3-T1`: installed target is self-contained and has no `agent.md`.
- `V3-A1`: vendor skill adapters are symlinks, never copies.
- `V3-H1`: hook events and hook inventory retain the v1.5 guarantees.
- `V3-I1`: installed inventory is manifest-tracked.

All v3 gates are MUST-fail from publication; there is no warning window for
repositories that explicitly declare the new major version.
