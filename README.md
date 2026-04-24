# EIIS — Eidolons Individual Install Standard

EIIS is the install contract every Eidolon repository satisfies. It is a
plain-text standard plus a standalone bash conformance checker. The Eidolons
nexus (`Rynaro/eidolons`) and every shipped Eidolon (ATLAS, SPECTRA, APIVR-Δ,
IDG, FORGE, VIGIL) all consume this contract.

- **Latest stable:** [EIIS v1.0](spec/eiis-1.0.md) (also reachable as
  [`SPEC.md`](SPEC.md), the symlink to the latest stable spec).
- **Manifest schema:** [`schemas/install.manifest.v1.json`](schemas/install.manifest.v1.json).
- **Conformance checker:** [`conformance/check.sh`](conformance/check.sh).
- **Skeleton template:** [`templates/eidolon-skeleton/`](templates/eidolon-skeleton/).
- **Implementors:** [IMPLEMENTORS.md](IMPLEMENTORS.md).

## What this repo is

This repo holds:

1. **The normative spec** in [`spec/eiis-1.0.md`](spec/eiis-1.0.md). RFC 8174
   (BCP 14) keywords; numbered §1–§7 sections; one file per minor version.
2. **JSON Schemas** in [`schemas/`](schemas/) for the
   `install.manifest.json` contract.
3. **A standalone bash conformance checker** in
   [`conformance/`](conformance/) that runs against any Eidolon repo
   without needing the nexus.
4. **A copy-paste skeleton** in [`templates/eidolon-skeleton/`](templates/eidolon-skeleton/)
   for third-party Eidolon authors.
5. **CI workflows** that lint shell scripts, validate the schemas, and run
   the conformance checker against the skeleton on every push.

## What this repo is NOT

- It is **not** an Eidolon. It does not get installed into consumer projects.
- It does **not** define the methodology content of any Eidolon. That lives
  in each Eidolon's own repo.
- It does **not** define the runtime behaviour of installed Eidolons.
- It does **not** define the schema for `eidolons.yaml` or `eidolons.lock` —
  those are nexus-owned.
- It does **not** publish to npm/pip/brew. Distribution is `git clone`.

## Quick start — third-party Eidolon author

```bash
git clone https://github.com/Rynaro/eidolons-eiis /tmp/eiis
cp -R /tmp/eiis/templates/eidolon-skeleton ./my-eidolon
cd my-eidolon
# Replace placeholders ({{EIDOLON_NAME}}, {{METHODOLOGY}}, {{VERSION}})
# with your values, then:
bash /tmp/eiis/conformance/check.sh .
```

If the checker exits 0, your repo satisfies EIIS v1.0's MUSTs. Exit code 4
means you pass MUSTs but have grandfathered warnings (expected for a fresh
template until you fill in `files_written`).

## Quick start — running the checker against an existing repo

```bash
bash /tmp/eiis/conformance/check.sh /path/to/some-eidolon-repo
bash /tmp/eiis/conformance/check.sh /path/to/some-eidolon-repo --json
bash /tmp/eiis/conformance/check.sh /path/to/some-eidolon-repo --level=MUST
```

Exit codes:

- `0` — passes all MUSTs at the declared `EIIS_VERSION`.
- `1` — generic failure (missing dir, unreadable files).
- `2` — fails one or more MUSTs.
- `3` — passes MUSTs but fails one or more SHOULDs.
- `4` — passes MUSTs, emits warn-only output (grandfathered drift).

See [`conformance/README.md`](conformance/README.md) for details.

## Versioning

EIIS uses SemVer at the document level. v1.0 is the first stable. v1.1 is
expected to add Codex (`codex` host) as an additive minor. v1.2 promotes the
warn-only drifts (D-3, D-6) to fail-only.

See [§6 of the spec](spec/eiis-1.0.md#6--versioning--compatibility) for the
full promotion timeline.

## Relationship to other repos

```
┌──────────────────────────┐
│  EIIS  (this repo)       │  Layer 1 — the install contract.
└────────────┬─────────────┘
             │ satisfied by
             ▼
┌──────────────────────────┐
│  Eidolon repos           │  Layer 2 — ATLAS, SPECTRA, APIVR-Δ,
│  (Rynaro/{ATLAS,…})      │  IDG, FORGE, VIGIL. Each has its own
│                          │  install.sh that satisfies §2.
└────────────┬─────────────┘
             │ orchestrated by
             ▼
┌──────────────────────────┐
│  Eidolons nexus          │  Layer 3 — Rynaro/eidolons. Vendors a
│  (Rynaro/eidolons)       │  copy of EIIS and uses the conformance
│                          │  checker as part of `eidolons sync`.
└────────────┬─────────────┘
             │ installs into
             ▼
┌──────────────────────────┐
│  Consumer project        │  Layer 4 — `eidolons.yaml` + `eidolons.lock`
└──────────────────────────┘  + `.eidolons/<member>/`.
```

See [`docs/relationship-to-nexus.md`](docs/relationship-to-nexus.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version: open an issue
first, then a PR against `main`. Spec changes require a SemVer bump and a
new `spec/eiis-X.Y.md` file.

## License

Apache-2.0. See [LICENSE](LICENSE).
