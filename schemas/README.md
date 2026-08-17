# schemas/

JSON Schemas for EIIS-defined artefacts.

| File | Purpose | EIIS version |
|---|---|---|
| [`install.manifest.v1.json`](install.manifest.v1.json) | Schema for `<target>/install.manifest.json` written by every Eidolon's `install.sh`. Defined by EIIS v1.0 §3. | v1.0 |
| [`install.manifest.draft.md`](install.manifest.draft.md) | Field-by-field rationale (informative). | v1.0 |
| [`package-manifest.v3.json`](package-manifest.v3.json) | Immutable v3 package metadata. | v3.0 |
| [`install-receipt.v1.json`](install-receipt.v1.json) | Consumer-specific installation and adapter state. | v3.0 |

`install.manifest.v1.json` is frozen for EIIS 1.x compatibility. EIIS v3
does not extend it.

## Validating a manifest

### Syntactic check (always available)

```bash
jq empty install.manifest.json
```

### Schema check with `ajv`

```bash
npm install -g ajv-cli
ajv validate \
  -s schemas/install.manifest.v1.json \
  -d /path/to/install.manifest.json
```

### Schema check with Python

```bash
pip install jsonschema
python3 -m jsonschema \
  --instance /path/to/install.manifest.json \
  schemas/install.manifest.v1.json
```

The EIIS conformance checker (`conformance/check.sh`) performs the
syntactic check unconditionally and the schema check when a validator is
on `PATH` — degrading gracefully to a structural field-presence check
otherwise.

## Future schema versions

When EIIS bumps to a new minor (e.g. v1.1 for Codex support), a sibling
file `install.manifest.v1.1.json` will be added here, and the
conformance checker will gain a `--target-version 1.1` option that
selects the matching schema. Older schemas stay in tree forever for
backward audits.
