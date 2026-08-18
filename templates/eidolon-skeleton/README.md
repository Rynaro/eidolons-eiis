# {{METHODOLOGY}}

{{ONE_LINE_DESCRIPTION}}

## Quick start

```bash
bash install.sh --target ./.eidolons/{{EIDOLON_NAME}} --hosts auto
```

## Files

| Path | Purpose |
|---|---|
| `PERSONA.md` | Bounded identity, triggers, authority, refusals, and handoffs. |
| `SPEC.md` | Normative methodology. |
| `skills/<methodology>/SKILL.md` | Unique skill discovery entrypoint. |
| `manifest.json` | Immutable package metadata. |
| `EIIS_VERSION` | Declares this repo targets EIIS v3.0.0. |
| `install.sh` | Package-only installer; host adapters are nexus-owned. |
| `schemas/` | Vendored package-manifest and install-receipt schemas. |

## EIIS conformance

This repo targets [EIIS v3.0](https://github.com/Rynaro/eidolons-eiis/blob/main/spec/eiis-3.0.md).
To verify locally:

```bash
git clone https://github.com/Rynaro/eidolons-eiis /tmp/eiis
bash /tmp/eiis/conformance/check.sh .
```

## License

{{LICENSE}}
