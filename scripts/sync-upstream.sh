#!/usr/bin/env bash
set -euo pipefail

# Mirrors upstream refs into origin while preserving the Aether namespace.
upstream_remote="${UPSTREAM_REMOTE:-upstream}"
upstream_url="${UPSTREAM_URL:-https://github.com/RightNow-AI/openfang.git}"
origin_remote="${ORIGIN_REMOTE:-origin}"
protected_branch_prefix="${PROTECTED_BRANCH_PREFIX:-aether/}"
protected_tag_prefix="${PROTECTED_TAG_PREFIX:-aether-}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "sync-upstream.sh must run inside a git repository." >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

upstream_branches_file="$tmpdir/upstream-branches.txt"
origin_branches_file="$tmpdir/origin-branches.txt"
upstream_tags_file="$tmpdir/upstream-tags.txt"
origin_tags_file="$tmpdir/origin-tags.txt"

if git remote get-url "$upstream_remote" >/dev/null 2>&1; then
  git remote set-url "$upstream_remote" "$upstream_url"
else
  git remote add "$upstream_remote" "$upstream_url"
fi

git fetch "$upstream_remote" --prune \
  "+refs/heads/*:refs/remotes/$upstream_remote/*" \
  "+refs/tags/*:refs/upstream-tags/*"

git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$upstream_remote" \
  | grep -v '^HEAD$' \
  | sort -u > "$upstream_branches_file"

git ls-remote --heads --refs "$origin_remote" \
  | awk '{sub("^refs/heads/", "", $2); print $2}' \
  | sort -u > "$origin_branches_file"

while IFS= read -r branch; do
  [ -n "$branch" ] || continue
  git push "$origin_remote" "refs/remotes/$upstream_remote/$branch:refs/heads/$branch" --force
done < "$upstream_branches_file"

while IFS= read -r branch; do
  [ -n "$branch" ] || continue
  case "$branch" in
    "$protected_branch_prefix"*)
      continue
      ;;
  esac

  if ! grep -Fxq -- "$branch" "$upstream_branches_file"; then
    git push "$origin_remote" ":refs/heads/$branch"
  fi
done < "$origin_branches_file"

git for-each-ref --format='%(refname:strip=2)' refs/upstream-tags \
  | sort -u > "$upstream_tags_file"

git ls-remote --tags --refs "$origin_remote" \
  | awk '{sub("^refs/tags/", "", $2); print $2}' \
  | sort -u > "$origin_tags_file"

while IFS= read -r tag; do
  [ -n "$tag" ] || continue
  git push "$origin_remote" "refs/upstream-tags/$tag:refs/tags/$tag" --force
done < "$upstream_tags_file"

while IFS= read -r tag; do
  [ -n "$tag" ] || continue
  case "$tag" in
    "$protected_tag_prefix"*)
      continue
      ;;
  esac

  if ! grep -Fxq -- "$tag" "$upstream_tags_file"; then
    git push "$origin_remote" ":refs/tags/$tag"
  fi
done < "$origin_tags_file"
