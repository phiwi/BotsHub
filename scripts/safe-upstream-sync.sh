#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_REMOTE="upstream"
DEFAULT_UPSTREAM_BRANCH="master"
MODE="merge"
REMOTE="$DEFAULT_REMOTE"
UPSTREAM_BRANCH="$DEFAULT_UPSTREAM_BRANCH"
PUSH_AFTER_SYNC=false
PUSH_REMOTE="origin"

print_usage() {
  cat <<'EOF'
Safely integrate updates from an upstream remote into the current branch.

Usage:
  safe-upstream-sync.sh [options]

Options:
  --remote <name>       Upstream remote name (default: upstream)
  --branch <name>       Upstream branch name (default: master)
  --rebase              Rebase current branch onto remote/branch
  --merge               Merge remote/branch into current branch (default)
  --push                Push current branch after successful sync
  --push-remote <name>  Remote used with --push (default: origin)
  -h, --help            Show this help

Examples:
  ./scripts/safe-upstream-sync.sh
  ./scripts/safe-upstream-sync.sh --rebase
  ./scripts/safe-upstream-sync.sh --remote origin --branch master --push --push-remote upstream
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
    --remote)
      [[ $# -ge 2 ]] || fail "Missing value for --remote"
      REMOTE="$2"
      shift 2
      ;;
    --branch)
      [[ $# -ge 2 ]] || fail "Missing value for --branch"
      UPSTREAM_BRANCH="$2"
      shift 2
      ;;
    --rebase)
      MODE="rebase"
      shift
      ;;
    --merge)
      MODE="merge"
      shift
      ;;
    --push)
      PUSH_AFTER_SYNC=true
      shift
      ;;
    --push-remote)
      [[ $# -ge 2 ]] || fail "Missing value for --push-remote"
      PUSH_REMOTE="$2"
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

git remote get-url "$REMOTE" >/dev/null 2>&1 || fail "Remote '$REMOTE' does not exist"

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

log "Fetching '$REMOTE'..."
git fetch "$REMOTE" --prune

UPSTREAM_REF="$REMOTE/$UPSTREAM_BRANCH"
git rev-parse --verify "$UPSTREAM_REF" >/dev/null 2>&1 || fail "Upstream ref '$UPSTREAM_REF' not found"

if [[ "$MODE" == "rebase" ]]; then
  log "Rebasing '$CURRENT_BRANCH' onto '$UPSTREAM_REF'..."
  if ! git rebase "$UPSTREAM_REF"; then
    echo "[$SCRIPT_NAME] ERROR: Rebase failed." >&2
    echo "[$SCRIPT_NAME] Resolve conflicts, then run 'git rebase --continue' or 'git rebase --abort'" >&2
    echo "[$SCRIPT_NAME] Stash was NOT popped. Re-apply manually after rebase completes." >&2
    exit 1
  fi
else
  log "Merging '$UPSTREAM_REF' into '$CURRENT_BRANCH'..."
  if ! git merge --no-edit "$UPSTREAM_REF"; then
    echo "[$SCRIPT_NAME] ERROR: Merge failed." >&2
    echo "[$SCRIPT_NAME] Resolve conflicts, then run 'git merge --continue' or 'git merge --abort'" >&2
    echo "[$SCRIPT_NAME] Stash was NOT popped. Re-apply manually after merge completes." >&2
    exit 1
  fi
fi

if ! restore_stash; then
  fail "Sync succeeded but stash restore needs manual conflict resolution"
fi

if [[ "$PUSH_AFTER_SYNC" == true ]]; then
  git remote get-url "$PUSH_REMOTE" >/dev/null 2>&1 || fail "Push remote '$PUSH_REMOTE' does not exist"
  log "Pushing '$CURRENT_BRANCH' to '$PUSH_REMOTE'..."
  git push "$PUSH_REMOTE" "$CURRENT_BRANCH"
fi

log "Done. '$CURRENT_BRANCH' is synchronized with '$UPSTREAM_REF'."