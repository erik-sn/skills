---
name: overlay-skill
description: Personal overlay for this fork. Writes a new skill that augments an upstream one instead of editing it. Use when customizing, wrapping, or extending an existing skill, when working under skills/personal, or when a change would otherwise edit an upstream SKILL.md, README, AGENTS.md, plugin manifest, or docs page.
---

Call the Skill tool with "writing-for-agents" before authoring any overlay.

This repo is a personal fork of `mattpocock/skills`. Upstream files stay byte-for-byte theirs so the nightly sync can merge. Personal behaviour lives in an **overlay**: a new skill under `skills/personal/` that names the upstream skill, then states only the delta.

## Decide the branch

- **Overlay**: the user wants different behaviour from an existing skill. Name it `overlay-<upstream-name>` (the basename must not collide with any other skill directory in `skills/`).
- **New personal skill**: the work is not a delta on an existing skill. Still create it under `skills/personal/`, with a descriptive name. Same bucket, no `overlay-` prefix.

**Done when:** you can name the directory and say which upstream skill (if any) it calls.

## Leave upstream untouched

Do not edit, move, or delete anything under:

- `skills/engineering/`, `skills/productivity/`, `skills/misc/`, `skills/in-progress/`, `skills/deprecated/`
- `AGENTS.md`, `CLAUDE.md`, the top-level `README.md`, `docs/`, `.claude-plugin/`, `.agents/`
- `skills/engineering/ask-matt/` (the upstream router; a fork overlay must not patch it)

Fork-only paths are listed in the repo-root file `FORK.md`. Add new fork-only files next to those, never by overwriting an upstream path.

**Done when:** `git diff` against `HEAD` has no hunks in the paths above.

## Write the overlay

1. Create `skills/personal/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) matching this repo's invocation rules in `.agents/invocation.md`.
2. Add `skills/personal/<name>/agents/openai.yaml` (Codex UI metadata; for a user-invoked overlay, include `policy.allow_implicit_invocation: false`).
3. In the overlay body, tell the agent to **call the Skill tool with the upstream skill name**, then apply the delta. Do not copy the upstream `SKILL.md` into the overlay. The overlay is the delta; the upstream skill remains the source of the shared steps.
4. Append one line to `skills/personal/README.md` linking the new skill.

A model-invoked overlay that should win over its upstream parent uses the same trigger terms in its `description`, plus a clause that this fork prefers the overlay. Distinct directory basename still applies: `overlay-tdd` can trigger on "tdd" / "red-green-refactor"; it must not be named `tdd`.

**Done when:** the overlay directory has `SKILL.md` and `agents/openai.yaml`, the bucket README lists it, and the overlay body calls the upstream skill by Skill tool rather than inlining it.

## Link it

Run `scripts/link-skills.sh` so the new directory is symlinked into `~/.claude/skills` and `~/.agents/skills`.

**Done when:** the script prints a `linked <name>` line for the overlay.
