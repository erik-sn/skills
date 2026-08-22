#!/usr/bin/env bash
set -euo pipefail

# Install the morning origin pull on this machine. Idempotent: existing
# config and existing schedule are left alone. Linux/macOS/WSL use crontab
# and XDG. Native Windows (Git Bash) uses schtasks and %APPDATA%.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TASK_NAME="skills-fork-morning-pull"
DEFAULT_HOUR=8
DEFAULT_MINUTE=0

windows_native() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  return 1
}

config_dir() {
  if windows_native && [[ -n "${APPDATA:-}" ]]; then
    printf '%s' "$APPDATA/skills-fork"
  else
    printf '%s' "${XDG_CONFIG_HOME:-$HOME/.config}/skills-fork"
  fi
}

schedule_exists() {
  if windows_native; then
    schtasks /Query /TN "$TASK_NAME" >/dev/null 2>&1
  else
    crontab -l 2>/dev/null | grep -q "$TASK_NAME"
  fi
}

write_default_config() {
  local dir="$1" file="$2"
  mkdir -p "$dir"
  cat >"$file" <<EOF
SKILLS_REPO=$REPO
HOUR=$DEFAULT_HOUR
MINUTE=$DEFAULT_MINUTE
EOF
  echo "wrote config $file"
}

install_unix() {
  local script="$1" hour="$2" minute="$3" line tmp
  line="$minute $hour * * * /bin/bash $script"
  tmp="$(mktemp)"
  crontab -l 2>/dev/null | grep -v "$TASK_NAME" | grep -v "pull-and-relink.sh" >"$tmp" || true
  printf '%s\n' "# $TASK_NAME" "$line" >>"$tmp"
  crontab "$tmp"
  rm -f "$tmp"
  echo "installed crontab: $line"
}

install_windows() {
  local script="$1" hour="$2" minute="$3" dir="$4"
  local bash_win cmd st
  if ! command -v cygpath >/dev/null 2>&1; then
    echo "error: cygpath missing; run this installer from Git Bash" >&2
    exit 1
  fi
  bash_win="$(cygpath -w "$(command -v bash)")"
  cmd="$dir/morning-pull.cmd"
  # cmd is the Task Scheduler target; recreate only when installing a new task
  printf '@echo off\r\n"%s" -lc "%s"\r\n' "$bash_win" "$script" >"$cmd"
  st="$(printf '%02d:%02d' "$hour" "$minute")"
  schtasks /Create /TN "$TASK_NAME" /SC DAILY /ST "$st" /TR "$(cygpath -w "$cmd")"
  echo "installed scheduled task $TASK_NAME at $st"
}

dir="$(config_dir)"
cfg="$dir/morning.env"
mkdir -p "$dir"

if [[ -f "$cfg" ]]; then
  echo "config exists ($cfg), leaving it"
else
  write_default_config "$dir" "$cfg"
fi

# shellcheck disable=SC1090
source "$cfg"
SKILLS_REPO="${SKILLS_REPO:-$REPO}"
HOUR="${HOUR:-$DEFAULT_HOUR}"
MINUTE="${MINUTE:-$DEFAULT_MINUTE}"
SCRIPT="$SKILLS_REPO/scripts/pull-and-relink.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "error: $SCRIPT does not exist (check SKILLS_REPO in $cfg)" >&2
  exit 1
fi

if schedule_exists; then
  echo "schedule $TASK_NAME already exists, leaving it"
  exit 0
fi

if windows_native; then
  install_windows "$SCRIPT" "$HOUR" "$MINUTE" "$dir"
else
  install_unix "$SCRIPT" "$HOUR" "$MINUTE"
fi
