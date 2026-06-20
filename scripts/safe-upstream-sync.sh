#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SOURCE_REMOTE="origin"
SOURCE_BRANCH="master"
FORK_REMOTE="upstream"
PUSH_TO_FORK=false

print_usage() {
  cat <<'EOF'
Simple and safe sync helper.

Default behavior:
- stash local changes when needed
- fetch origin
- merge origin/master into current branch
- restore stash

Usage:
  safe-upstream-sync.sh [options]

Options:
  --source <name>       Source remote to fetch/merge from (default: origin)
  --branch <name>       Source branch to merge (default: master)
  --push                Push current branch after sync
  --fork-remote <name>  Push target for --push (default: upstream)
  -h, --help            Show this help

Examples:
  ./scripts/safe-upstream-sync.sh
  ./scripts/safe-upstream-sync.sh --push
  ./scripts/safe-upstream-sync.sh --source origin --branch master --push --fork-remote upstream
EOF
}

log() {
  echo "[$SCRIPT_NAME] $*"
}

fail() {
  echo "[$SCRIPT_NAME] ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      [[ $# -ge 2 ]] || fail "Missing value for --source"
      SOURCE_REMOTE="$2"
      shift 2
      ;;
    --branch)
      [[ $# -ge 2 ]] || fail "Missing value for --branch"
      SOURCE_BRANCH="$2"
      shift 2
      ;;
    --push)
      PUSH_TO_FORK=true
      shift
      ;;
    --fork-remote)
      [[ $# -ge 2 ]] || fail "Missing value for --fork-remote"
      FORK_REMOTE="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repository"

CURRENT_BRANCH="$(git branch --show-current)"
[[ -n "$CURRENT_BRANCH" ]] || fail "Detached HEAD is not supported. Checkout a branch first."

git remote get-url "$SOURCE_REMOTE" >/dev/null 2>&1 || fail "Source remote '$SOURCE_REMOTE' does not exist"

STASH_CREATED=false
STASH_LABEL="safe-upstream-sync $(date +%Y-%m-%dT%H:%M:%S)"
STASH_REF=""

find_sync_stash_ref() {
  git stash list --format='%gd %gs' | awk -v label="$STASH_LABEL" '$0 ~ label {print $1; exit}'
}

if [[ -n "$(git status --porcelain)" ]]; then
  log "Working tree is dirty. Creating stash: $STASH_LABEL"
  git stash push -u -m "$STASH_LABEL" >/dev/null
  STASH_CREATED=true
  STASH_REF="$(find_sync_stash_ref)"
  [[ -n "$STASH_REF" ]] || fail "Could not locate created stash entry"
else
  log "Working tree is clean."
fi

restore_stash() {
  if [[ "$STASH_CREATED" == true ]]; then
    log "Restoring stashed changes..."
    if ! git stash pop --index "$STASH_REF" >/dev/null; then
      echo "[$SCRIPT_NAME] WARNING: Could not auto-apply stash cleanly." >&2
      echo "[$SCRIPT_NAME] Resolve conflicts and use: git stash list / git stash show / git stash apply" >&2
      return 1
    fi
    log "Stashed changes restored."
  fi
  return 0
}

log "Fetching '$SOURCE_REMOTE'..."
git fetch "$SOURCE_REMOTE" --prune

SOURCE_REF="$SOURCE_REMOTE/$SOURCE_BRANCH"
git rev-parse --verify "$SOURCE_REF" >/dev/null 2>&1 || fail "Source ref '$SOURCE_REF' not found"

log "Merging '$SOURCE_REF' into '$CURRENT_BRANCH'..."
if ! git merge --no-edit "$SOURCE_REF"; then
  echo "[$SCRIPT_NAME] ERROR: Merge failed." >&2
  echo "[$SCRIPT_NAME] Resolve conflicts, then run 'git merge --continue' or 'git merge --abort'" >&2
  echo "[$SCRIPT_NAME] Stash was NOT popped. Re-apply manually after merge completes." >&2
  exit 1
fi

if ! restore_stash; then
  fail "Sync succeeded but stash restore needs manual conflict resolution"
fi

if [[ "$PUSH_TO_FORK" == true ]]; then
  git remote get-url "$FORK_REMOTE" >/dev/null 2>&1 || fail "Fork remote '$FORK_REMOTE' does not exist"
  log "Pushing '$CURRENT_BRANCH' to '$FORK_REMOTE'..."
  git push "$FORK_REMOTE" "$CURRENT_BRANCH"
fi

log "Done. '$CURRENT_BRANCH' is synchronized with '$SOURCE_REF'."