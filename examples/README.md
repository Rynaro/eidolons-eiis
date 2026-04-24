# examples/

Worked examples demonstrating EIIS-conformant artefacts.

| File | Demonstrates |
|---|---|
| [`manifest-conformant.json`](manifest-conformant.json) | A valid `install.manifest.json` with all required fields (§3.1) and every optional field populated. Validates against `schemas/install.manifest.v1.json`. |

## Running the validations

```bash
jq empty examples/manifest-conformant.json
python3 -m jsonschema \
  --instance examples/manifest-conformant.json \
  schemas/install.manifest.v1.json
```
