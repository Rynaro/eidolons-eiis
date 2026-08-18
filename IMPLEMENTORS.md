# EIIS Implementors

> EIIS 3.0 replaces `agent.md` and copied vendor skills with `PERSONA.md`
> and canonical `skills/<methodology>/SKILL.md` directories. New work starts
> from `templates/eidolon-skeleton/` and [`spec/eiis-3.0.md`](spec/eiis-3.0.md).
> Entries declaring EIIS 1.x remain historical compatibility records.

This file lists known-conformant Eidolons. Each entry pins a tag and the
EIIS version the repo declares via its `EIIS_VERSION` file.

Format:

```
- [Repo](https://github.com/owner/repo) — vX.Y.Z — EIIS_VERSION X.Y — <status>
```

Where `<status>` is one of:

- `conformant` — passes all MUSTs at the declared EIIS version (exit 0).
- `conformant-with-warnings` — passes all MUSTs but emits warn-only
  output for grandfathered drifts (exit 4).
- `pending d-N[, d-N…]` — passes most MUSTs but is awaiting reconciliation
  of one or more drifts before promotion to fail-only enforcement (the
  drift IDs reference the table in `spec/eiis-1.0.md` Citations §
  "Drift register cross-reference").

## Conformant Eidolons

> **Note (v1.0 ship)**: at v1.0.0 publication on 2026-04-24, every
> shipped Eidolon listed below is in the `pending d-6` state because
> none of them have an `EIIS_VERSION` file yet. The drift-D-6 enforcement
> for v1.0 is **warn-only** and the conformance checker exits 4 (warn,
> not fail) for these entries until the per-Eidolon patch wave lands
> (`fix/eiis-version-file` PRs in each external repo). See
> `Rynaro/eidolons/docs/specs/eiis-bootstrap/SPEC.md` §T.5 for the
> migration plan.

- [Rynaro/ATLAS](https://github.com/Rynaro/ATLAS) — v1.0.3 — EIIS_VERSION 1.0 — pending d-6
- [Rynaro/SPECTRA](https://github.com/Rynaro/SPECTRA) — v4.2.8 — EIIS_VERSION 1.0 — pending d-6
- [Rynaro/APIVR-Delta](https://github.com/Rynaro/APIVR-Delta) — v3.0.3 — EIIS_VERSION 1.0 — pending d-6
- [Rynaro/IDG](https://github.com/Rynaro/IDG) — v1.1.3 — EIIS_VERSION 1.0 — pending d-6
- [Rynaro/VIGIL](https://github.com/Rynaro/VIGIL) — v1.0.1 — EIIS_VERSION 1.0 — pending d-6
- [Rynaro/FORGE](https://github.com/Rynaro/FORGE) — v1.1.1 — EIIS_VERSION 1.0 — pending d-1, d-3, d-4, d-6

## Third-party implementors

None at v1.0.0 ship time. Add yourself by opening a PR against this file.
The conformance checker must pass for your repo before the PR will merge.

```bash
git clone https://github.com/Rynaro/eidolons-eiis /tmp/eiis
bash /tmp/eiis/conformance/check.sh /path/to/your-eidolon
```

## Drift legend

| ID | Drift | Status |
|---|---|---|
| **D-1** | `--shared-dispatch` flag absent | SHOULD in v1.0; MUST in v1.2 (2027-04-24) |
| **D-3** | `files_written` empty | MUST, warn-only in v1.0; MUST-fail in v1.2 |
| **D-4** | Marker convention violated in shared-dispatch writes | MUST, fail from v1.0 (release blocker for the affected repo) |
| **D-6** | `EIIS_VERSION` file missing | MUST, warn-only in v1.0; MUST-fail in v1.2 |
