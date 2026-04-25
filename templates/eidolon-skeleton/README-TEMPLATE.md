# Using the EIIS skeleton template

This directory is a copy-paste starting point for a new EIIS-conformant
Eidolon repository.

## Setup

```bash
git clone https://github.com/Rynaro/eidolons-eiis /tmp/eiis
cp -R /tmp/eiis/templates/eidolon-skeleton ./my-eidolon
cd my-eidolon

# Replace placeholders. Pick a lowercase slug (matches ^[a-z][a-z0-9-]*$).
EIDOLON_NAME="sentry"
METHODOLOGY="SENTRY"
VERSION="0.1.0"

find . -type f \( -name '*.md' -o -name '*.sh' -o -name 'EIIS_VERSION' \) \
  -exec sed -i.bak \
    -e "s/{{EIDOLON_NAME}}/${EIDOLON_NAME}/g" \
    -e "s/{{METHODOLOGY}}/${METHODOLOGY}/g" \
    -e "s/{{VERSION}}/${VERSION}/g" \
    {} +
find . -name '*.bak' -delete

# Verify locally:
bash /tmp/eiis/conformance/check.sh .
# Expected: exit 0 (or 4 if you haven't filled in the example manifest yet).

# Initialise git:
git init && git add . && git commit -m "Initial commit (EIIS v1.0 skeleton)"
```

## What you still need to fill in

The skeleton ships with these placeholders that `sed` does not handle
because they appear in prose. Search and replace each:

- `{{ONE_LINE_DESCRIPTION}}` (in `agent.md`, `README.md`)
- `{{P0_RULE_1}}`, `{{P0_RULE_2}}`, `{{P0_RULE_3}}`
- `{{PIPELINE_SUMMARY}}` (in `agent.md`)
- `{{CYCLE_DESCRIPTION}}` (in `AGENTS.md`)
- `{{PHASE_1}}`, `{{PHASE_1_PURPOSE}}`, `{{PHASE_1_SLUG}}`
- `{{OUTPUT_1}}`, `{{OUTPUT_2}}`
- `{{UPSTREAM_LIST}}`, `{{DOWNSTREAM_LIST}}`
- `{{INVOCATION_HINT}}`
- `{{LICENSE}}`, `{{RELEASE_DATE}}`, `{{OWNER}}`, `{{REPO}}`

Once the methodology content is real, drop this `README-TEMPLATE.md` file
and rely on `README.md` instead.
