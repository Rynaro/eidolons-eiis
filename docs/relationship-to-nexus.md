# EIIS ↔ Eidolons nexus relationship

The Eidolons nexus (`Rynaro/eidolons`) is the orchestrator that consumes
EIIS. This document explains how the two repos relate.

## The four-layer model

```
┌──────────────────────────┐
│  Layer 1: EIIS           │  This repo. The install contract.
│  (Rynaro/eidolons-eiis)  │  Authoritative for §1–§7.
└────────────┬─────────────┘
             │ satisfied by
             ▼
┌──────────────────────────┐
│  Layer 2: Eidolon repos  │  Six shipped: ATLAS, SPECTRA, APIVR-Δ,
│  (Rynaro/{ATLAS,…})      │  IDG, FORGE, VIGIL. Each ships an
│                          │  install.sh that satisfies §2 + a
│                          │  manifest schema honoring §3.
└────────────┬─────────────┘
             │ orchestrated by
             ▼
┌──────────────────────────┐
│  Layer 3: Eidolons nexus │  Vendors a copy of EIIS at
│  (Rynaro/eidolons)       │  ~/.eidolons/cache/eiis@<ver>/
│                          │  and delegates to conformance/check.sh.
└────────────┬─────────────┘
             │ installs into
             ▼
┌──────────────────────────┐
│  Layer 4: Consumer repo  │  eidolons.yaml + eidolons.lock
│                          │  + .eidolons/<member>/.
└──────────────────────────┘
```

## What the nexus consumes from EIIS

After the nexus migration PR (`feat/eiis-v1.0-bootstrap`) lands, the
nexus will consume EIIS in two places:

1. **`cli/install.sh`** — the curl-pipe bootstrap clones EIIS at the
   version pinned by `roster/index.yaml`'s `eiis_required` field into
   `~/.eidolons/cache/eiis@<ver>/`.
2. **`cli/src/lib.sh:eiis_check`** — replaces the inline 5-file
   existence check with a delegation to
   `~/.eidolons/cache/eiis@<ver>/conformance/check.sh`. The inline
   5-file check stays as a fallback when the vendored copy is missing
   (defensive parity with `yaml_to_json`'s yq/python3 fallback).

## What the nexus does NOT consume from EIIS

- The spec text. The nexus links to EIIS for human readers; it does not
  re-render or duplicate the prose.
- The fixtures. EIIS's bats fixtures are for EIIS's own CI.
- The templates. Third-party Eidolon authors clone EIIS directly for
  the skeleton; the nexus does not redistribute templates.

## What EIIS does NOT define

- The `eidolons.yaml` and `eidolons.lock` schemas. Those are
  nexus-owned (see `roster/index.yaml` and `cli/src/sync.sh` in
  `Rynaro/eidolons`).
- The roster format. Nexus-owned.
- The CLI dispatch convention. Nexus-owned.
- Methodology content. Per-Eidolon.

## Cross-repo coordination

When EIIS bumps a minor (v1.0 → v1.1):

1. EIIS publishes the new tag.
2. Each Eidolon that wants v1.1 features (e.g. Codex support) opens a
   PR adding the relevant features and bumping its `EIIS_VERSION` file.
3. The nexus may bump `roster/index.yaml`'s `eiis_required` from `1.0`
   to `1.1` after enough Eidolons have opted in. Doing so is a
   maintainer call, not automatic.

When EIIS promotes a warn-only field to MUST-fail (e.g. D-3 in v1.2):

1. Every Eidolon listed in `IMPLEMENTORS.md` is verified to have the
   relevant fix tagged.
2. EIIS bumps the conformance checker to flip the warn branch to fail.
3. EIIS publishes v1.2.
4. The nexus's CI will start failing for any Eidolon that hasn't
   landed the fix — by design.

## See also

- `spec/eiis-1.0.md` — the normative spec.
- `Rynaro/eidolons/docs/architecture.md` — the nexus's architecture
  doc, which references EIIS as Layer 1.
- `Rynaro/eidolons/docs/specs/eiis-bootstrap/SPEC.md` — the SPECTRA
  design document that drove this repo's bootstrap.
