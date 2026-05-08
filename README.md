# EIIS — Eidolons Individual Install Standard

EIIS is the install contract every Eidolon repository satisfies. It is a
plain-text standard plus a standalone bash conformance checker. The Eidolons
nexus (`Rynaro/eidolons`) and every shipped Eidolon (ATLAS, SPECTRA, APIVR-Δ,
IDG, FORGE, VIGIL) all consume this contract.

- **Latest stable:** [EIIS v1.2](spec/eiis-1.2.md) (also reachable as
  [`SPEC.md`](SPEC.md), the symlink to the latest stable spec).
- **Manifest schema:** [`schemas/install.manifest.v1.json`](schemas/install.manifest.v1.json).
- **Conformance checker:** [`conformance/check.sh`](conformance/check.sh).
- **Skeleton template:** [`templates/eidolon-skeleton/`](templates/eidolon-skeleton/).
- **Implementors:** [IMPLEMENTORS.md](IMPLEMENTORS.md).

## What this repo is

This repo holds:

1. **The normative spec** in [`spec/eiis-1.2.md`](spec/eiis-1.2.md) (latest
   stable). RFC 8174 (BCP 14) keywords; numbered §1–§7 sections; one file per
   minor version. Prior versions: [`spec/eiis-1.1.md`](spec/eiis-1.1.md),
   [`spec/eiis-1.0.md`](spec/eiis-1.0.md).
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

EIIS uses SemVer at the document level.

- **v1.0** — first stable (2026-04-24).
- **v1.1** — additive: Codex (`codex` host) recognised; §4.5 Codex subagent
  contract (2026-04-25). v1.0 Eidolons remain conformant.
- **v1.2** — additive: ECL composition clause (§4.6); OPTIONAL `ECL_VERSION`
  file; warn-only E0/E1 conformance gates (2026-05-08). v1.1 Eidolons remain
  conformant. This is the current stable.
- **v1.3** — expected to revisit drift register promotions (D-3, D-6 to
  hard-fail) and any ECL gate promotions warranted by adoption data.

See [§6 of the spec](spec/eiis-1.2.md#6--versioning--compatibility) for the
full promotion timeline.

## Relationship to other repos

**Relationship to ECL:** [ECL (`Rynaro/eidolons-ecl`)](https://github.com/Rynaro/eidolons-ecl)
is a sibling standard at Layer 1 governing the wire format and hand-off
contract for runtime inter-Eidolon communication. EIIS and ECL compose but do
not overlap: EIIS is the install contract; ECL is the runtime hand-off
contract. See [§4.6 of the spec](spec/eiis-1.2.md#46--ecl-composition-v12).

```
┌──────────────────────────┐  ┌──────────────────────────┐
│  EIIS  (this repo)       │  │  ECL  (Rynaro/eidolons-  │
│  install contract        │  │  ecl) hand-off contract  │
│                          │  │                          │
│  Layer 1a                │  │  Layer 1b (sibling)      │
└────────────┬─────────────┘  └────────────┬─────────────┘
             │ satisfied by                │ emitted by
             ▼                             ▼
┌──────────────────────────────────────────────────────────┐
│  Eidolon repos  (Rynaro/{ATLAS, SPECTRA, APIVR-Δ, …})   │
│  Layer 2 — each install.sh satisfies EIIS §2;            │
│  each emitter satisfies ECL when ECL_VERSION is present. │
└────────────────────────────┬─────────────────────────────┘
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
