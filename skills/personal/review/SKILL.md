---
name: review
description: Independently review a ticket's PR and write the findings into its ticket bundle, as a session the bundle can trace.
argument-hint: "ATEF-<n>"
disable-model-invocation: true
---

# Review a ticket's PR

Run this in a **fresh session, separate from the one that did the work** - the separation is the point: an independent transcript, and findings formed without the implementer's reasoning in context.

Read [`../work/TICKET-BUNDLE.md`](../work/TICKET-BUNDLE.md) first: it defines the bundle, the domain config, the manifest, and session capture. Resolve the ticket's PR from the bundle's manifest.

## Independence

Review against the **ticket and the PR only**. The bundle's `plan.md` holds the implementer's reasoning - reading it first inherits its blind spots and turns the review into reviewing the justification. Only after your findings are formed, read `plan.md` and add a short section noting where findings contradict recorded decisions: a finding that survives knowing the rationale is a stronger finding, and one the rationale answers gets that answer cited.

## Procedure

Follow the review-handoff procedure at `~/.claude/skills/review-handoff/SKILL.md` - every finding proven, dead ends recorded, nothing posted to the code host or the tracker - with two overrides:

- The document is written to the bundle as `review.md`, not to `~/projects/reviews/`.
- After it is written, stamp the bundle's manifest (review session id, full transcript path, one log line) and copy your transcript per session capture.

Done when `review.md` exists in the bundle, the manifest is stamped, and your closing reply tells the user to return to the work session with `/work <KEY> apply the review`.
