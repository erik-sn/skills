# Personal fork

This clone is [erik-sn/skills](https://github.com/erik-sn/skills), forked from [mattpocock/skills](https://github.com/mattpocock/skills). Upstream skills stay as Matt ships them. Personal behaviour is a new skill under `skills/personal/` that augments an upstream one. Call the Skill tool with "overlay-skill" for that procedure.

The top-level `README.md` is Matt's install story (official Claude plugin, `npx skills add mattpocock/skills`). Use this file instead. The official plugin does not ship `skills/personal/`.

## Initial setup

On each machine:

```bash
git clone git@github.com:erik-sn/skills.git
cd skills
bash scripts/link-skills.sh
bash scripts/install-morning-cron.sh
```

`link-skills.sh` symlinks every skill (including overlays) into `~/.claude/skills` and `~/.agents/skills`. Cursor reads those directories. The morning installer is idempotent: existing config and schedule are left alone.

Once per GitHub repo (already done on this fork), after `sync-upstream.yml` is on `origin/main`:

```bash
bash scripts/setup-personal-fork.sh
```

That disables the inherited Release workflow, enables nightly Sync upstream, and installs the morning pull if this machine has no schedule yet. Leftover-conflict auto-resolve is optional: `bash scripts/setup-anthropic-key.sh` when you have an Anthropic key.

Do not also install `mattpocock-skills` from the official marketplace on the same machine if you want the overlays: you would have Matt's grilling and this fork's at once.

## Why overlays

The nightly job merges `mattpocock/skills` into this repo. An edited upstream `SKILL.md` becomes a merge conflict every time Matt touches the same file. A new path under `skills/personal/` does not.

Do not edit `AGENTS.md`, `CLAUDE.md`, the top-level `README.md`, `docs/`, `.claude-plugin/`, `.agents/`, or anything under `skills/engineering/`, `skills/productivity/`, `skills/misc/`, `skills/in-progress/`, or `skills/deprecated/`. `ask-matt` is upstream; do not patch it to advertise personal skills. The list lives in [`skills/personal/README.md`](./skills/personal/README.md).

## Grilling on this fork

`/grill-me` is still the command. Call the Skill tool with "overlay-grilling": TLDR at the top of each round, shuffled options, ➡️ for the recommendation, no filler choices.

## Nightly GitHub sync

[`.github/workflows/sync-upstream.yml`](./.github/workflows/sync-upstream.yml) runs at 06:00 UTC (02:00 America/New_York) and on `workflow_dispatch`. It fetches `mattpocock/skills` `main`, merges with `--no-ff`, and pushes. The merge message includes `[skip ci]` so the inherited Release workflow does not fire on that push.

Conflicts:

1. Mechanical, by path: prefixes in [`scripts/fork-only-paths.txt`](./scripts/fork-only-paths.txt) keep **ours**; every other conflicted path takes **theirs**.
2. Leftovers (add/add, rename, unclassified) go to Anthropic Sonnet in the same job (`ANTHROPIC_API_KEY` repo secret, model `claude-sonnet-4-6`).
3. If the secret is missing or the model cannot finish, abort the merge and open one GitHub issue titled "Upstream sync conflict" (comment on it if it is already open).

Alerts beyond that issue are out of scope.

After this workflow file is on `origin/main`:

```bash
bash scripts/setup-personal-fork.sh
bash scripts/setup-anthropic-key.sh
```

The first script disables Release, enables Sync upstream, dispatches a test run, and installs the morning pull if this machine has no schedule yet. The second sets `ANTHROPIC_API_KEY`. Scheduled workflows on a fork stay off until they have been enabled and run once.

## Morning local pull

08:00 local, `origin/main` only, skip if the working tree is dirty, then `scripts/link-skills.sh`.

```bash
bash scripts/install-morning-cron.sh
```

Idempotent. Machine-specific values live outside git:

- Linux, macOS, WSL: `~/.config/skills-fork/morning.env` and crontab (`skills-fork-morning-pull`)
- Native Windows (Git Bash): `%APPDATA%\skills-fork\morning.env` and Task Scheduler (`skills-fork-morning-pull`), which starts Git Bash on `pull-and-relink.sh`

If the config file already exists, it is not overwritten. If the schedule already exists, it is not rewritten. A new machine has neither, so the installer writes defaults from that clone (hour 8) and installs once.

Log: `~/.local/state/skills-fork/pull-and-relink.log` (Unix) or `%LOCALAPPDATA%\skills-fork\pull-and-relink.log` (native Windows).

## Fork-only paths

The machine-readable list is [`scripts/fork-only-paths.txt`](./scripts/fork-only-paths.txt). Add a line there when you add a fork-only file.
