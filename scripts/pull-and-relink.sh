#!/usr/bin/env bash
set -euo pipefail

# Fast-forward this clone from origin/main and re-link skills if HEAD moved.
# Skip when dirty or not on main. Invoked by the morning schedule.

REPO="$(cd "$(dirname "$0")/.." && pwd)"

windows_native() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  return 1
}

if windows_native && [[ -n "${LOCALAPPDATA:-}" ]]; then
  LOG_DIR="$LOCALAPPDATA/skills-fork"
else
  LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/skills-fork"
fi
LOG="$LOG_DIR/pull-and-relink.log"
mkdir -p "$LOG_DIR"

{
  echo "=== $(date -Is) ==="

  export PATH="/usr/bin:/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
  export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new}"

  cd "$REPO"

  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$branch" != "main" ]]; then
    echo "not on main ($branch), skip"
    exit 0
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "dirty working tree, skip"
    exit 0
  fi

  git fetch origin
  local_sha="$(git rev-parse HEAD)"
  remote_sha="$(git rev-parse origin/main)"

  if [[ "$local_sha" == "$remote_sha" ]]; then
    echo "already up to date ($local_sha)"
    exit 0
  fi

  git pull --ff-only origin main
  bash "$REPO/scripts/link-skills.sh"
  echo "updated $local_sha -> $(git rev-parse HEAD)"
} >>"$LOG" 2>&1
