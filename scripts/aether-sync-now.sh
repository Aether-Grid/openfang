#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/aether-common.sh"
aether_repo_root
require_git_repo
require_command gh

repo="${AETHER_REPO:-Aether-Grid/openfang}"
ref="${AETHER_REF:-aether/main}"
workflow="${AETHER_SYNC_WORKFLOW:-upstream-sync.yml}"
wait_for_run=false

usage() {
  cat <<'EOF'
Trigger the upstream mirror workflow immediately.

Usage:
  scripts/aether-sync-now.sh [--wait] [--repo owner/name] [--ref branch]

Options:
  --wait        wait for the dispatched workflow run to finish
  --repo        GitHub repo to target (default: Aether-Grid/openfang)
  --ref         branch that owns the workflow file (default: aether/main)
  -h, --help    show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --wait)
      wait_for_run=true
      ;;
    --repo)
      shift
      [ "$#" -gt 0 ] || die "missing value for --repo"
      repo="$1"
      ;;
    --ref)
      shift
      [ "$#" -gt 0 ] || die "missing value for --ref"
      ref="$1"
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

gh auth status >/dev/null
gh workflow run "$workflow" --repo "$repo" --ref "$ref"
echo "Triggered $workflow on $repo@$ref"

if [ "$wait_for_run" != true ]; then
  exit 0
fi

run_id=""
for _ in 1 2 3 4 5 6; do
  run_id="$(gh run list \
    --repo "$repo" \
    --workflow "$workflow" \
    --branch "$ref" \
    --event workflow_dispatch \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId // ""')"

  if [ -n "$run_id" ]; then
    break
  fi

  sleep 2
done

[ -n "$run_id" ] || die "workflow run was dispatched but no run ID was found"

gh run watch "$run_id" --repo "$repo" --exit-status
gh run view "$run_id" --repo "$repo" --json url,status,conclusion --jq '.url'
