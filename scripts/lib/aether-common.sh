#!/usr/bin/env bash

aether_repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
  cd -- "$script_dir"
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "must run inside a git repository"
}

require_clean_worktree() {
  git diff --quiet || die "working tree has unstaged changes"
  git diff --cached --quiet || die "index has staged but uncommitted changes"
}

current_branch() {
  git rev-parse --abbrev-ref HEAD
}

ensure_local_branch() {
  git show-ref --verify --quiet "refs/heads/$1" || die "local branch not found: $1"
}

normalize_aether_tag() {
  case "$1" in
    aether-v*) printf '%s\n' "$1" ;;
    v*) printf 'aether-%s\n' "$1" ;;
    *) printf 'aether-v%s\n' "$1" ;;
  esac
}

tag_exists_anywhere() {
  git rev-parse -q --verify "refs/tags/$1" >/dev/null 2>&1 && return 0
  git ls-remote --tags --refs origin "$1" | grep -q .
}
