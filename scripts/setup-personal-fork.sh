#!/usr/bin/env bash
set -euo pipefail

# Idempotent machine setup: morning pull, then GitHub Actions wiring once
# sync-upstream.yml is on origin/main.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

bash "$REPO/scripts/install-morning-cron.sh"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is not installed; enable the Sync upstream workflow from the Actions tab after pushing." >&2
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not logged in; enable the Sync upstream workflow from the Actions tab after pushing." >&2
  exit 0
fi

if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  echo "no upstream tracking branch; push main, then re-run this script." >&2
  exit 0
fi

git fetch origin
if ! git cat-file -e "origin/main:.github/workflows/sync-upstream.yml" 2>/dev/null; then
  echo "sync-upstream.yml is not on origin/main yet. Push this commit, then re-run:" >&2
  echo "  bash scripts/setup-personal-fork.sh" >&2
  echo "  bash scripts/setup-anthropic-key.sh" >&2
  exit 0
fi

gh workflow disable "Release" >/dev/null 2>&1 && echo "disabled workflow: Release" || echo "Release workflow not present or already disabled"
gh workflow enable "Sync upstream" >/dev/null 2>&1 && echo "enabled workflow: Sync upstream" || echo "could not enable Sync upstream (open the Actions tab and enable it once)"
if gh workflow run "Sync upstream"; then
  echo "dispatched Sync upstream"
else
  echo "could not dispatch Sync upstream; run it once from the Actions tab so the nightly schedule starts." >&2
fi

if gh secret list 2>/dev/null | grep -q '^ANTHROPIC_API_KEY'; then
  echo "GitHub secret ANTHROPIC_API_KEY is set"
else
  echo "ANTHROPIC_API_KEY is not set. Leftover conflicts will open an issue until you run:" >&2
  echo "  bash scripts/setup-anthropic-key.sh" >&2
fi
