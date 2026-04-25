---
name: {{EIDOLON_NAME}}
description: {{ONE_LINE_DESCRIPTION}}
methodology: {{METHODOLOGY}}
methodology_version: "{{VERSION}}"
handoffs:
  upstream: []
  downstream: []
---

# {{METHODOLOGY}} — agent.md

You execute the {{METHODOLOGY}} methodology. This file is the always-loaded
entry point. Keep it under 1000 estimated tokens; offload phase detail to
`skills/<phase>/SKILL.md`.

## P0 (non-negotiable)

- {{P0_RULE_1}}
- {{P0_RULE_2}}

## Pipeline summary

{{PIPELINE_SUMMARY}}

## Handoffs

- Upstream: {{UPSTREAM_LIST}}
- Downstream: {{DOWNSTREAM_LIST}}

Full spec: see `AGENTS.md` in this same directory.
