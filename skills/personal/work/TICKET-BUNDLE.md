# Ticket bundle

Shared reference for `work` and `review`: one directory per ticket that relates a piece of work to the spec, the review, and the sessions that produced it - so a bug found later can be walked back to the full reasoning.

## Location

```
~/projects/<project>/tickets/<KEY>/
  manifest.md     identity + append-only log (this file is the audit trail)
  plan.md         requirements and implementation spec, out of the grill
  review.md       the review handoff, written by the review session
  sessions/       copied transcripts, one per session
```

`<project>` is the basename of `git rev-parse --show-toplevel`, normalized to the main checkout when running in a git worktree (a worktree path like `<repo>/.claude/worktrees/<name>` belongs to `<repo>`). Sessions in a worktree and in the main repo land in the same bundle.

## Domains

The repo's memory directory (named in your system prompt) carries the domain config in `agent-skills/`:

- `issue-tracker.md` - the ticket domain: which system, which project, which CLI, the status flow.
- `code-host.md` - the PR domain: which host, which CLI, branch/title/body conventions, merge strategy.

Read both before touching either system. A missing file means this repo is not onboarded: stop and offer to write it from the sibling repo's as a template. Both skills stay host-agnostic; everything system-specific lives in those two files.

## Manifest

The header block holds identity and is updated in place; the log is append-only - never rewrite a prior line.

```markdown
# <KEY> - <ticket title>

- project: <project>
- ticket: <ticket URL>
- branch: <branch>
- pr: <PR URL> (base: <base branch>)

## Spec inputs
- <the ticket description>
- <each planning doc treated as requirements, by path>

## Sessions
- work: <session id> <full transcript path>
- review: <session id> <full transcript path>

## Log
- <date> <one line per event>
```

Stamp the log at every gate, not at the end: an abandoned session must still leave a usable trail. Events worth a line: session started, spec inputs settled, plan approved, diff approved, PR opened, ticket transitioned, review written, review applied, pushed.

## Session capture

Your session id is the UUID directory segment in your scratchpad path; your transcript is `~/.claude/projects/<slug>/<session-id>.jsonl`. Record the **full path** in the manifest - worktree sessions live under a different project slug than the main checkout, and an id without its slug is hard to find later.

At completion (and only then - a mid-work copy is stale the moment the session continues), copy your transcript to `sessions/<role>-<session-id>.jsonl`, where `<role>` is `work` or `review`.
