# `install.manifest.v1.json` — field-by-field rationale

Cross-reference for `spec/eiis-1.0.md` §3. This document explains the
**why** behind each field. The schema in `install.manifest.v1.json` is the
machine-readable normative form; this document is informative.

## Required fields

### `eidolon`

Lowercase slug. Pattern: `^[a-z][a-z0-9-]*$`. Used as:

- The Eidolon's identity in the nexus roster (`roster/index.yaml`).
- The marker name in §4.1 dispatch blocks (`<!-- eidolon:atlas start -->`).
- The filename in §4.2 dispatch files (`.claude/agents/atlas.md`).

Lowercase-only avoids cross-OS case-sensitivity issues (macOS HFS+ /APFS
case-insensitivity vs Linux ext4 case-sensitivity).

### `version`

SemVer. Pattern: `^\d+\.\d+\.\d+$`. The Eidolon's release version at
install time.

**Drift D-5**: per-Eidolon installers historically hardcode this as
`EIDOLON_VERSION="1.0.0"` in the script. The nexus rewrites it
post-install to match the canonical git tag (`cli/src/sync.sh:241-254` in
the nexus). The override is permitted (§3.6); v2.0 deprecates it.

### `methodology`

The methodology name in conventional casing (e.g. `ATLAS`, `SPECTRA`,
`APIVR-Δ`). Intended as a human-readable label for `eidolons list`
output. No pattern constraint.

### `installed_at`

RFC 3339 / ISO 8601 UTC timestamp. The **only** non-deterministic field.
Every other required field MUST be content-determined.

Implementations commonly use `date -u +"%Y-%m-%dT%H:%M:%SZ"`.

### `target`

The install directory relative to consumer repo root. Conventionally
`./.eidolons/<eidolon>` (e.g. `./.eidolons/atlas`).

### `hosts_wired`

Array of host enum values. v1.0 enum: `claude-code`, `copilot`, `cursor`,
`opencode`, `raw`. v1.1 adds `codex`.

`raw` is the escape hatch when no host config is detected (e.g. a project
with no `.claude/`, `.github/`, `.cursor/`, or `.opencode/`). The
installer copies the methodology files but writes no dispatch files.

### `files_written`

Array of `{path, sha256, role, mode?}` objects. The complete inventory of
every file the installer created, appended to, or overwrote during this
run.

**Drift D-3**: FORGE today emits `[]` unconditionally. The nexus
consumes this array for the planned `eidolons remove` reverse-lookup. v1.0
declares it MUST-populated with **warn-only** enforcement until
2027-04-24; v1.2 promotes to MUST-fail.

#### Roles

| Role | Meaning |
|---|---|
| `entry-point` | `agent.md`, `AGENTS.md`, `CLAUDE.md` — always-loaded surfaces. |
| `spec` | The Eidolon's normative methodology document. |
| `skill` | A progressive-disclosure skill file under `skills/<phase>/SKILL.md`. |
| `template` | An output skeleton under `templates/`. |
| `dispatch` | A host-side dispatch file (claude-code subagent, copilot instructions, etc.). |
| `manifest` | The `install.manifest.json` itself (rarely listed; usually omitted). |
| `other` | Anything else (schemas, evals, license copies). |

#### Modes

| Mode | Meaning |
|---|---|
| `created` | The file did not exist before this run. |
| `appended` | The file existed; the installer added content (typically marker-bounded). |
| `overwritten` | The file existed; the installer replaced its content. |

The `mode` field is OPTIONAL; absence is interpreted as `created`.

## Optional fields

### `handoffs_declared`

`{upstream: string[], downstream: string[]}`. The Eidolon's pipeline
neighbours, as declared in its `agent.md` frontmatter. Used by the nexus
to validate `roster/index.yaml` handoff entries.

### `token_budget`

`{entry: integer, working_set_target: integer}`. The measured token
count of `agent.md` (`entry`) and the methodology's stated working-set
budget. EIIS only mandates `entry ≤ 1000` as a SHOULD (§2.4 exit code 4).

### `security`

`{reads_repo, reads_network, writes_repo, persists}`. Self-declared
security posture. ATLAS for example sets:

```json
{
  "reads_repo": true,
  "reads_network": false,
  "writes_repo": false,
  "persists": [".atlas/.memex"]
}
```

Useful for sandbox-aware consumers but not currently enforced by the
nexus or by EIIS conformance.

## Validation

```bash
# Syntactic validation (always runs):
jq empty install.manifest.json

# Schema validation (when ajv or python-jsonschema is available):
ajv validate -s schemas/install.manifest.v1.json -d install.manifest.json
# or:
python3 -m jsonschema --schema schemas/install.manifest.v1.json install.manifest.json
```

The EIIS conformance checker (`conformance/check.sh`) performs the
syntactic check unconditionally and the schema check when a validator is
available — degrading gracefully to a structural field-presence check
otherwise.
