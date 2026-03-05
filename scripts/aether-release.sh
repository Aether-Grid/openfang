#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/aether-common.sh"
aether_repo_root
require_git_repo
require_command git

branch="${AETHER_WORK_BRANCH:-aether/main}"
push_branch=true
tag_name=""

usage() {
  cat <<'EOF'
Create and push an Aether release tag from the fork work branch.

Usage:
  scripts/aether-release.sh <version-or-tag> [--branch name] [--no-pull]

Examples:
  scripts/aether-release.sh 0.3.24.1
  scripts/aether-release.sh v0.3.24.1
  scripts/aether-release.sh aether-v0.3.24.1

Options:
  --branch      source branch for the tag (default: aether/main)
  --no-pull     skip fetching and fast-forwarding the branch from origin
  -h, --help    show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --branch)
      shift
      [ "$#" -gt 0 ] || die "missing value for --branch"
      branch="$1"
      ;;
    --no-pull)
      push_branch=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "unknown argument: $1"
      ;;
    *)
      if [ -n "$tag_name" ]; then
        die "tag/version argument provided more than once"
      fi
      tag_name="$(normalize_aether_tag "$1")"
      ;;
  esac
  shift
done

[ -n "$tag_name" ] || die "missing version or tag argument"

require_clean_worktree
ensure_local_branch "$branch"
git switch "$branch"

if [ "$push_branch" = true ]; then
  git fetch origin
  git pull --ff-only origin "$branch"
fi

if tag_exists_anywhere "$tag_name"; then
  die "tag already exists: $tag_name"
fi

git tag -a "$tag_name" -m "Aether release $tag_name"
git push origin "$tag_name"

echo "Created and pushed $tag_name from $branch"
