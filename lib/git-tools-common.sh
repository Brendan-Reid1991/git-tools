#!/usr/bin/env bash

error() {
  printf 'Error: %s\n' "$*" >&2
}

die() {
  error "$@"
  exit 1
}

require_git_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error "not inside a Git repository."
    exit 2
  fi
}

current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null
}
