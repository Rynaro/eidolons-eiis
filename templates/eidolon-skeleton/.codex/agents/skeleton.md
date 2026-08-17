---
name: skeleton
description: {{METHODOLOGY}} methodology subagent for OpenAI Codex.
tools:
  - Read
  - Grep
  - Glob
---

# {{METHODOLOGY}} — Codex subagent

This file is the per-Eidolon subagent surface for OpenAI Codex
(see <https://developers.openai.com/codex/subagents>). The frontmatter
above is REQUIRED by EIIS v1.1 §4.5.

> When you fork this template, rename this file to `<your-slug>.md` and
> update the frontmatter `name:` to match (`<your-slug>`). The filename
> and the frontmatter slug must agree.

When Codex delegates to this subagent, load the canonical persona at
`./.eidolons/{{EIDOLON_NAME}}/PERSONA.md` and methodology at
`./.eidolons/{{EIDOLON_NAME}}/SPEC.md`.

## P0 (non-negotiable)

- {{P0_RULE_1}}
- {{P0_RULE_2}}

## Invocation

Address the agent as: "{{METHODOLOGY}}, {{INVOCATION_HINT}}".
