# {{METHODOLOGY}} — vendor-neutral methodology summary

This file is the methodology's authoritative reference. Vendor-specific
surfaces (`CLAUDE.md`, `.claude/agents/<name>.md`, etc.) point to this
file for full rules.

## Identity

- **Eidolon name:** `{{EIDOLON_NAME}}` (lowercase slug)
- **Methodology:** {{METHODOLOGY}}
- **Version:** {{VERSION}}
- **EIIS:** v1.0 (see `EIIS_VERSION` file)

## Cycle

{{CYCLE_DESCRIPTION}}

## P0 (non-negotiable rules)

1. {{P0_RULE_1}}
2. {{P0_RULE_2}}
3. {{P0_RULE_3}}

## Phase pipeline

| Phase | Purpose | Skill file |
|---|---|---|
| {{PHASE_1}} | {{PHASE_1_PURPOSE}} | `skills/{{PHASE_1_SLUG}}/SKILL.md` |

## Outputs

- {{OUTPUT_1}}
- {{OUTPUT_2}}

## Handoffs

- **Upstream:** {{UPSTREAM_LIST}}
- **Downstream:** {{DOWNSTREAM_LIST}}
