# Personal

Fork-only skills for this clone of `mattpocock/skills`. They are not in the Claude plugin and they are not on the top-level README. Nightly sync merges upstream into this repo; these files exist so that merge stays a clean add, not a conflict with edited upstream skills.

When a change would otherwise edit an upstream skill, create an overlay here instead. Call the Skill tool with "overlay-skill".

- **[overlay-skill](./overlay-skill/SKILL.md)**: Write a new skill that augments an upstream one instead of editing it. Model-invoked.
- **[overlay-grilling](./overlay-grilling/SKILL.md)**: Grilling overlay: TLDR each round, shuffled options, no filler choices. Silent over `grilling` / `grill-me`. Model-invoked.
- **[work](./work/SKILL.md)**: Drive one ticket from spec to pushed PR, writing a ticket bundle that traces the work to its sessions, spec, and review. User-invoked.
- **[review](./review/SKILL.md)**: Independently review a ticket's PR in a fresh session and write the findings into its bundle. User-invoked.
