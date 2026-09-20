#!/usr/bin/env bash
set -eo pipefail

__here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../common.sh
source "${GIT_TOOLS_LIB_DIR:-${__here}/..}/common.sh"
unset __here

usage() {
  cat <<'EOF'
  Usage: gra new <branch_name> [<base>]

  Creates and switches to a new branch. If <base> is given the new branch starts from that ref; otherwise it starts from the current HEAD.
EOF
}

NAME=""
BASE=""

if [[ $# -gt 2 ]]; then
    usage >&2
    usage_error "Too many arguments."
fi


for arg in "$@"; do
    case "$arg" in
        -h | --help)
            usage
            exit 0
            ;;
        -*)
            usage >&2
            usage_error "unknown option: $arg"
            ;;
        *)
            if [[ -z "$NAME" ]]; then
                NAME="$arg"
                continue
            fi
            if [[ -z "$BASE" ]]; then
                BASE="$arg"
                continue
            fi
    esac
done

[[ -n "$NAME" ]] || usage_error "Branch name is required."

if [[ -z "$BASE" ]]; then
    exec git switch -c "$NAME"
else
    exec git switch -c "$NAME" "$BASE"
fi