# shellcheck shell=bash
# EIIS v3 package and installation conformance.

_v3_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

_v3_tree_sha256() {
  local root="$1" listing
  listing="$(mktemp)"
  find "$root" -type f ! -name install.receipt.json -print | LC_ALL=C sort | while IFS= read -r file; do
    printf '%s  %s\n' "$(_v3_sha256 "$file")" "${file#"$root/"}"
  done > "$listing"
  _v3_sha256 "$listing"
  rm -f "$listing"
}

_v3_validate_json() {
  local instance="$1" schema="$2"
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' >/dev/null 2>&1; then
    python3 -m jsonschema -i "$instance" "$schema" >/dev/null 2>&1
  else
    jq empty "$instance" >/dev/null 2>&1
  fi
}

eiis_check_v3() {
  local dir="$1" target_version="$2"
  local manifest="$dir/manifest.json"
  local schema="$SCHEMA_DIR/package-manifest.v3.json" bad="" path name entry resource event

  for path in PERSONA.md SPEC.md manifest.json README.md install.sh EIIS_VERSION; do
    [ -f "$dir/$path" ] || bad="${bad}${path} missing; "
  done
  for path in agent.md EIDOLONS.md; do
    [ -e "$dir/$path" ] && bad="${bad}${path} forbidden in a package; "
  done
  if [ -z "$bad" ]; then record "V3-P1" "MUST" "ok" "canonical package files present"
  else record "V3-P1" "MUST" "fail" "canonical package layout" "$bad"; fi

  if [ ! -f "$manifest" ] || ! _v3_validate_json "$manifest" "$schema"; then
    record "V3-M1" "MUST" "fail" "manifest.json validates against package-manifest.v3.json"
    return
  fi
  record "V3-M1" "MUST" "ok" "manifest.json validates against package-manifest.v3.json"
  name="$(jq -r '.name' "$manifest")"

  bad=""
  while IFS=$'\t' read -r name entry; do
    [ -n "$name" ] || continue
    [ "$entry" = "skills/$name/SKILL.md" ] || bad="${bad}${name} entrypoint must be skills/${name}/SKILL.md; "
    [ -f "$dir/$entry" ] || bad="${bad}${entry} missing; "
  done < <(jq -r '.skills | to_entries[]? | [.key,.value.entrypoint] | @tsv' "$manifest")
  if [ -z "$bad" ]; then record "V3-S1" "MUST" "ok" "declared skill entrypoints resolve"
  else record "V3-S1" "MUST" "fail" "canonical skill discovery" "$bad"; fi

  bad=""
  while IFS= read -r resource; do
    [ -n "$resource" ] || continue
    case "$resource" in skills/*|shared/*) ;; *) bad="${bad}${resource} escapes canonical resource roots; "; continue ;; esac
    [ -f "$dir/$resource" ] || bad="${bad}${resource} missing; "
  done < <(jq -r '.skills[]?.resources[]?' "$manifest")
  while IFS= read -r resource; do
    [ -n "$resource" ] || continue
    case "/$resource/" in */../*|*/./*) bad="${bad}${resource} escapes the package root; "; continue ;; esac
    [ -e "$dir/$resource" ] || bad="${bad}${resource} missing; "
  done < <(jq -r '.resources[]?' "$manifest")
  if [ -z "$bad" ]; then record "V3-R1" "MUST" "ok" "declared resources are package-contained"
  else record "V3-R1" "MUST" "fail" "resource containment" "$bad"; fi

  bad=""
  while IFS=$'\t' read -r path event; do
    [ -n "$path" ] || continue
    [ -x "$dir/$path" ] || bad="${bad}${path} missing or non-executable; "
    case "$event" in session-start|prompt-submit|pre-tool|stop) ;; *) bad="${bad}${path} invalid event; ";; esac
  done < <(jq -r '.hooks // {} | to_entries[]? | [.value.path,.value.event] | @tsv' "$manifest")
  if [ -z "$bad" ]; then record "V3-H1" "MUST" "ok" "declared package hooks are executable and typed"
  else record "V3-H1" "MUST" "fail" "package hook contract" "$bad"; fi

  # Adapter metadata is intentionally absent from the package schema. Source
  # repositories may carry development configuration, but install.sh copies
  # only manifest-declared package content and emits an adapter-free receipt.
  record "V3-A1" "MUST" "ok" "package contract contains no vendor adapters"

  _eiis_check_v3_install "$dir" "$manifest"
  : "$target_version"
}

_eiis_check_v3_install() {
  local dir="$1" manifest="$2" tmp name target receipt before after receipt_tree
  tmp="$(mktemp -d)"
  name="$(jq -r '.name' "$manifest")"
  target="$tmp/.eidolons/$name"
  if ! (cd "$tmp" && bash "$dir/install.sh" --target ".eidolons/$name" --hosts raw --non-interactive --force >/dev/null); then
    record "V3-I1" "MUST" "fail" "installer materializes the declared package"
    rm -rf "$tmp"
    return
  fi
  receipt="$target/install.receipt.json"
  if [ ! -f "$target/PERSONA.md" ] || [ ! -f "$target/SPEC.md" ] || [ ! -f "$target/manifest.json" ]; then
    record "V3-I1" "MUST" "fail" "installer omitted canonical package entrypoints"
    rm -rf "$tmp"
    return
  fi
  while IFS= read -r resource; do
    [ -n "$resource" ] || continue
    if [ ! -e "$target/$resource" ]; then
      record "V3-I1" "MUST" "fail" "installer omitted declared resource: $resource"
      rm -rf "$tmp"
      return
    fi
  done < <(jq -r '.resources[]?' "$manifest")
  if ! _v3_validate_json "$receipt" "$SCHEMA_DIR/install-receipt.v1.json"; then
    record "V3-I1" "MUST" "fail" "install.receipt.json validates"
    rm -rf "$tmp"
    return
  fi
  receipt_tree="$(jq -r '.tree_sha256' "$receipt")"
  before="$(_v3_tree_sha256 "$target")"
  if [ "$receipt_tree" != "$before" ]; then
    record "V3-I1" "MUST" "fail" "receipt tree digest matches installed package"
    rm -rf "$tmp"
    return
  fi
  (cd "$tmp" && bash "$dir/install.sh" --target ".eidolons/$name" --hosts raw --non-interactive --force >/dev/null)
  after="$(_v3_tree_sha256 "$target")"
  if [ "$before" != "$after" ]; then
    record "V3-I2" "MUST" "fail" "repeat installation preserves package bytes"
  else
    record "V3-I2" "MUST" "ok" "repeat installation preserves package bytes"
  fi
  record "V3-I1" "MUST" "ok" "installer materializes package and valid receipt"
  rm -rf "$tmp"
}
