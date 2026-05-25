# Conformant

Conformant fixture for EIIS self-tests

## Quick start

```bash
bash install.sh --target ./.eidolons/conformant --hosts auto
```

## Files

| Path | Purpose |
|---|---|
| `agent.md` | Always-loaded entry-point (≤1000 tokens). |
| `AGENTS.md` | Vendor-neutral methodology summary. |
| `CLAUDE.md` | Claude Code surface (pointer to `AGENTS.md`). |
| `EIIS_VERSION` | Declares this repo targets EIIS v1.0. |
| `install.sh` | Installer (EIIS v1.0 §2 conformant). |
| `schemas/install.manifest.v1.json` | Vendored manifest schema. |

## EIIS conformance

This repo targets [EIIS v1.0](https://github.com/Rynaro/eidolons-eiis/blob/main/spec/eiis-1.0.md).
To verify locally:

```bash
git clone https://github.com/Rynaro/eidolons-eiis /tmp/eiis
bash /tmp/eiis/conformance/check.sh .
```

## License

Apache-2.0
