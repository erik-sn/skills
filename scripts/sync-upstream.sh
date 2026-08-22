#!/usr/bin/env bash
set -euo pipefail

# Merge mattpocock/skills into main. Mechanical ours/theirs by path first
# (see scripts/fork-only-paths.txt). Anthropic Sonnet only on leftovers
# (add/add, rename, anything still unmerged). Local runs do not push.

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/mattpocock/skills.git}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"
ISSUE_TITLE="Upstream sync conflict"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
FORK_ONLY_LIST="$REPO/scripts/fork-only-paths.txt"

is_fork_only() {
  local rel="${1#./}" prefix p
  while IFS= read -r prefix || [[ -n "$prefix" ]]; do
    [[ "$prefix" =~ ^[[:space:]]*# ]] && continue
    prefix="${prefix%%#*}"
    prefix="${prefix#"${prefix%%[![:space:]]*}"}"
    prefix="${prefix%"${prefix##*[![:space:]]}"}"
    [[ -z "$prefix" ]] && continue
    prefix="${prefix#./}"
    p="${prefix%/}"
    if [[ "$rel" == "$p" || "$rel" == "$p"/* ]]; then
      return 0
    fi
  done < "$FORK_ONLY_LIST"
  return 1
}

unmerged_paths() {
  git diff --name-only --diff-filter=U -z | tr '\0' '\n' | sed '/^$/d'
}

stages_for() {
  git ls-files -u -- "$1" | awk '{print $3}' | sort -u | tr '\n' ' '
}

is_leftover() {
  local path="$1" stages
  stages="$(stages_for "$path")"
  # add/add: ours and theirs, no base
  if [[ "$stages" == *"2"* && "$stages" == *"3"* && "$stages" != *"1"* ]]; then
    return 0
  fi
  # both-modified, or a one-sided add/delete: mechanical
  if [[ "$stages" == *"1"* && "$stages" == *"2"* && "$stages" == *"3"* ]]; then
    return 1
  fi
  if [[ "$stages" == *"2"* && "$stages" != *"3"* ]]; then
    return 1
  fi
  if [[ "$stages" == *"3"* && "$stages" != *"2"* ]]; then
    return 1
  fi
  # rename / unclassified
  return 0
}

open_conflict_issue() {
  local body="$1"
  [[ "${GITHUB_ACTIONS:-}" == "true" ]] || return 0
  command -v gh >/dev/null 2>&1 || return 0
  local existing
  existing="$(gh issue list --search "${ISSUE_TITLE} in:title" --state open --json number --jq '.[0].number // empty')"
  if [[ -z "$existing" ]]; then
    gh issue create --title "$ISSUE_TITLE" --body "$body"
  else
    gh issue comment "$existing" --body "$body"
  fi
}

fail_conflict() {
  local why="$1"
  echo "error: $why" >&2
  git merge --abort || true
  open_conflict_issue "$why

See FORK.md and scripts/fork-only-paths.txt."
  exit 1
}

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is not clean" >&2
  exit 1
fi

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git checkout --quiet main
fi

git fetch "$UPSTREAM_URL" "$UPSTREAM_REF"
upstream_sha="$(git rev-parse FETCH_HEAD)"

if git merge-base --is-ancestor "$upstream_sha" HEAD; then
  echo "already up to date with $UPSTREAM_URL $UPSTREAM_REF ($upstream_sha)"
  exit 0
fi

date_utc="$(date -u +%Y-%m-%d)"
msg="chore: sync upstream ${date_utc} [skip ci]"

set +e
git merge --no-ff --no-edit -m "$msg" "$upstream_sha"
merge_status=$?
set -e

if [[ "$merge_status" -eq 0 ]]; then
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    git push origin HEAD:refs/heads/main
    echo "pushed merge of $upstream_sha"
  else
    echo "merged $upstream_sha locally; push when ready"
  fi
  exit 0
fi

if [[ ! -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]]; then
  echo "error: merge failed without a conflict" >&2
  exit 1
fi

echo "merge conflict; mechanical resolve by path"

leftovers=()
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if is_leftover "$path"; then
    leftovers+=("$path")
    echo "leftover $path"
    continue
  fi
  if is_fork_only "$path"; then
    echo "ours (fork-only) $path"
    git checkout --ours -- "$path"
  else
    echo "theirs (upstream) $path"
    git checkout --theirs -- "$path"
  fi
  git add -- "$path"
done < <(unmerged_paths)

if (( ${#leftovers[@]} )); then
  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    fail_conflict "Nightly sync from ${UPSTREAM_URL} (${UPSTREAM_REF} @ ${upstream_sha}) left leftovers on ${date_utc} and ANTHROPIC_API_KEY is unset.

Leftovers:
$(printf '%s\n' "${leftovers[@]}")"
  fi
  if ! python3 "$REPO/scripts/resolve-merge-leftovers.py" "${leftovers[@]}"; then
    fail_conflict "Nightly sync from ${UPSTREAM_URL} (${UPSTREAM_REF} @ ${upstream_sha}) leftover resolver failed on ${date_utc}.

Leftovers:
$(printf '%s\n' "${leftovers[@]}")"
  fi
  git add -- "${leftovers[@]}"
fi

if [[ -n "$(unmerged_paths)" ]]; then
  fail_conflict "Nightly sync from ${UPSTREAM_URL} (${UPSTREAM_REF} @ ${upstream_sha}) still has unmerged paths on ${date_utc}."
fi

git commit --no-edit

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  git push origin HEAD:refs/heads/main
  echo "pushed merge of $upstream_sha"
else
  echo "merged $upstream_sha locally; push when ready"
fi
