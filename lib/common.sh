#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers for the git-tools scripts.
#
# Exit code policy used by callers:
#   0  success
#   1  generic runtime error  (use `die`)
#   2  usage / argument error (use `usage_error`)

error() {
  printf 'Error: %s\n' "$*" >&2
}

die() {
  error "$@"
  exit 1
}

usage_error() {
  error "$@"
  exit 2
}

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "not inside a Git repository."
}

current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null
}
