# EIIS — Design rationale

This document records the long-form reasoning behind the choices in
`spec/eiis-1.0.md`. The spec is the normative source; this is the
informative companion.

## Why a separate repo?

Three reasons.

1. **Audience.** A third-party Eidolon author needs a document to read
   that is not buried inside the Eidolons nexus. EIIS sits above the
   nexus and above any individual Eidolon repo, so it earns its own URL.
2. **Lifecycle.** EIIS evolves at a different cadence than the nexus or
   any Eidolon. A v1.0-conformant Eidolon stays valid even as v1.1
   ships. Versioning the standard separately makes that auditable.
3. **Single source of truth.** Before v1.0, "EIIS" was referenced in
   seven places across the nexus and the shipped Eidolons but defined
   nowhere. Centralising the document makes drift detectable.

## Why bash for the conformance checker?

`bash 3.2`, `jq`, `git`, and POSIX coreutils are the same baseline the
nexus already requires. Adding a Python or Node toolchain just to run
the checker would push the dependency surface beyond `curl | bash`.

The trade-off is verbosity — the `lib/checks-*.sh` scripts are bigger
than equivalent Python would be. Acceptable for the ecosystem size.

## Why a single-file spec per minor?

LSP, OpenAPI, Conventional Commits, and SemVer all do this. The
benefits:

- Old conformance claims stay auditable. An Eidolon declaring
  `EIIS_VERSION 1.0` can be checked against `spec/eiis-1.0.md` years
  from now.
- Reviewers can see the diff between minors as a normal git diff
  (`spec/eiis-1.0.md` → `spec/eiis-1.1.md`) without wading through a
  combined doc with version conditionals.
- The `SPEC.md` symlink always points at the latest stable, giving
  drive-by readers a stable URL.

Downsides:

- Some duplication between `spec/eiis-1.0.md` and `spec/eiis-1.1.md`.
  Mitigated by the v1.1 doc being a delta against v1.0 ("§2 amendment.
  Add `codex` to `--hosts` LIST values…") rather than a full rewrite.

## Why warn-only for D-3 and D-6?

The two drifts affect every shipped Eidolon at v1.0 ship time:

- **D-3** (`files_written` empty): one repo (FORGE) emits the empty
  array unconditionally.
- **D-6** (`EIIS_VERSION` file): all six shipped Eidolons lack the
  file.

If v1.0 hard-failed on either of these, the standard would ship in a
state where every implementor fails it on day one. That's a credibility
problem for the standard.

The warn-only window (12 months, target 2027-04-24) gives each
implementor time to land a patch release. The conformance checker emits
exit code 4 for these — humanly visible as `[WARN]` lines but
acceptable in CI by default. The promotion to MUST-fail in v1.2 is
calendared into §6.3 of the spec.

## Why fail-from-v1.0 for D-4?

D-4 is the marker convention violation in FORGE's `CLAUDE.md` write.
Unlike D-3 and D-6 (which affect many Eidolons in a benign way), D-4 is
a single repo's bug that breaks a downstream feature (`eidolons remove`
reverse-lookup). The fix is small (replace one `printf` block with the
`upsert_eidolon_block` helper from ATLAS).

Holding the standard hostage to the FORGE patch would punish other
implementors. Calling it a hard fail from v1.0 puts pressure on the
FORGE patch wave specifically, without affecting any other Eidolon.

## Why no `--strict` mode in v1.0?

The first wave is naturally warn-only. A `--strict` flag that promotes
warn-only to fail would be useful for CI lanes that want to opt into
v1.2 semantics ahead of the date — but that's exactly the use case that
v1.1's Codex addendum can ship. Punting `--strict` to v1.1 keeps v1.0
narrow.

## Why bash 3.2?

macOS ships `/bin/bash` at 3.2 and homebrew bash is not on default
`PATH` for many users. The Eidolons nexus had bash 4-ism regressions in
the past (`116df8f`, `6a5689a` in nexus history) and the bats CI lane
on `macos-latest` is the canary.

`bash 3.2` rules out:

- Associative arrays (`declare -A`).
- Case conversion (`${var,,}` / `${var^^}`).
- `readarray` / `mapfile`.
- `&>>` redirect.

Workarounds: parallel arrays for k/v lookups; `tr` for case conversion;
`while IFS= read -r line` loops for stdin slurping; `>> file 2>&1` for
combined redirect.

## Why no `INSTALL_STATE/` directory?

Earlier drafts considered a sidecar journal at `.eidolons/<name>/INSTALL_STATE/`
mirroring how `apt-get` keeps `dpkg/info/`. v1.0 doesn't ship it because:

- `files_written` (§3.3) already provides the removal map.
- The marker convention (§4.1) provides idempotent shared-dispatch updates.
- Adding `INSTALL_STATE/` would expand the file surface that meta-installers
  must understand.

If `eidolons remove` reverse-lookup proves insufficient in practice,
v2.0 may revisit.

## Why not publish to npm/pip/brew?

The same reasoning as the nexus's `curl | bash` choice (see the nexus's
`docs/architecture.md` "Why not a package manager"). EIIS is small,
git-clone is the install path, and adding a package manager
indirection would buy us version pinning in a tool the nexus doesn't
need.

## Citations as informative, not normative

§4.3 of the spec lists vendor documentation (Anthropic, GitHub, Cursor,
OpenCode, OpenAI Codex). EIIS does not enforce vendor frontmatter
shapes because:

- The vendors evolve independently.
- An Eidolon can check vendor frontmatter validity at install time as
  part of its own contract; EIIS only needs the file location.

The trade-off: an EIIS-conformant Eidolon can produce a host file that
the host vendor rejects (e.g. malformed Cursor MDC frontmatter). EIIS
doesn't catch that. The vendor-side runtime does.
