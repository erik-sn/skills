---
name: work
description: Drive one ticket from spec to pushed PR, leaving a ticket bundle that traces the work back to its sessions, spec, and review.
argument-hint: "ATEF-<n> [start | apply the review]"
disable-model-invocation: true
---

# Work a ticket

Drive one ticket through spec alignment, implementation, and PR - writing the ticket bundle as you go, so the work stays traceable to the reasoning that produced it.

Read [`TICKET-BUNDLE.md`](TICKET-BUNDLE.md) first: it defines the bundle directory, the domain config, the manifest, and session capture. Resolve the domains and open (or create) the bundle before anything else.

The phase comes from the argument, never from inspecting the bundle's state. No phase given and no manifest exists: start. No phase given and a manifest exists: ask which phase in one line.

## Start

**1. Spec.** Fetch the ticket and its comments via the ticket domain. Collect every planning doc the ticket references or the user names - the ticket carries the requirements; implementation reasoning is what the grill produces next, so a thin ticket with rich planning docs is normal. Record all of them under `## Spec inputs` in the manifest: when a bug later turns out to be a spec misread, this list is the first question answered.

**2. Grill.** Call the Skill tool with "overlay-grilling" and interview until shared understanding of both the requirements and the implementation approach. Write `plan.md`: the requirements as agreed, then the implementation spec that came out of the grill - decisions, rejected alternatives, and why. Gate: the user approves the plan before any code.

**3. Implement.** Follow the repo's own conventions and checks (its CLAUDE.md is the source of truth). Done when the full test suite, lint, and typecheck are green and every generated artifact is regenerated. Gate: stop and let the user review the diff. Commit on their approval, in their commit-message style.

**4. PR.** Draft the title and body per the PR domain's conventions. Gate: show both; one yes covers the push and the create. Then offer the ticket transition the issue tracker's flow names for "in review". Stamp the manifest (branch, PR, transition), copy your transcript per session capture, and tell the user the next move: a fresh session running `/review <KEY>`.

## Apply the review

The review session has written `review.md` into the bundle.

**1. Read and verify.** Read `review.md` and the manifest. Re-verify each blocking finding yourself before acting on it - a review is a claim until you have reproduced it.

**2. Grill the judgement calls.** Mechanical findings (regeneration, renames, stale comments) you just fix. Anything that is a decision - scope, contract shape, whether a finding is this ticket's to fix - goes through "overlay-grilling" with the user before code changes.

**3. Apply and push.** Make the changes, get the checks green, commit, and push on the user's word. Append what was decided and what was deferred to `plan.md`. Stamp the manifest, copy your transcript.

One review round is the default; a second happens only when the user asks for it. The human reviews the PR last - this workflow prepares that review, it does not replace it.
