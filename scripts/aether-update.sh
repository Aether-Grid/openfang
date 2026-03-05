#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/aether-common.sh"
aether_repo_root
require_git_repo
require_command git

mode="rebase"
run_sync=false
wait_for_sync=false
branch="${AETHER_WORK_BRANCH:-aether/main}"

usage() {
  cat <<'EOF'
Update the Aether work branch from the mirrored main branch.

Usage:
  scripts/aether-update.sh [--merge|--rebase] [--sync-now] [--wait] [--branch name]

Options:
  --rebase      replay the Aether branch onto origin/main (default)
  --merge       merge origin/main into the Aether branch
  --sync-now    trigger the upstream mirror workflow before updating
  --wait        wait for the workflow run when used with --sync-now
  --branch      branch to update (default: aether/main)
  -h, --help    show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --rebase)
      mode="rebase"
      ;;
    --merge)
      mode="merge"
      ;;
    --sync-now)
      run_sync=true
      ;;
    --wait)
      wait_for_sync=true
      ;;
    --branch)
      shift
      [ "$#" -gt 0 ] || die "missing value for --branch"
      branch="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

if [ "$wait_for_sync" = true ] && [ "$run_sync" != true ]; then
  die "--wait can only be used together with --sync-now"
fi

require_clean_worktree
ensure_local_branch "$branch"

if [ "$run_sync" = true ]; then
  sync_args=()
  [ "$wait_for_sync" = true ] && sync_args+=(--wait)
  "$(dirname -- "${BASH_SOURCE[0]}")/aether-sync-now.sh" "${sync_args[@]}"
fi

git fetch origin
git switch "$branch"

case "$mode" in
  rebase)
    git rebase origin/main
    git push --force-with-lease origin "$branch"
    ;;
  merge)
    git merge --no-ff origin/main
    git push origin "$branch"
    ;;
esac

read -r behind ahead < <(git rev-list --left-right --count origin/main...HEAD)

echo "$branch updated with $mode"
echo "Ahead of origin/main: $ahead"
echo "Behind origin/main: $behind"
