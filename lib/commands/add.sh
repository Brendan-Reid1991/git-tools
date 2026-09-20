#!/usr/bin/env bash

set -e

__here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../common.sh
source "${GIT_TOOLS_LIB_DIR:-${__here}/..}/common.sh"
unset __here

usage() {
  cat <<'EOF'
Usage: gra add [options] [--] <file>...

Replaces `git add`, with the option to also commit (and retry if the commit fails).

If no commit message is given, the files are staged as normal.

Options:
  -m, --message <msg>   Commit message (optional)
      --retry N         Maximum commit attempts (default: 4).
  -h, --help            Show this help.

Examples:
  gra add src/main.sh -m "fix: tighten argument parsing"
  gra add . -m "chore: snapshot all local changes"
EOF
}

MESSAGE=""
MAX_ATTEMPTS=4
FILES=()

no_empty_message() {
    if [[ -z "$MESSAGE" ]]; then
        usage_error "Message cannot be empty."
    fi
}

validate_attempts() {
    if [[ ! "$MAX_ATTEMPTS" =~ ^[1-9][0-9]*$ ]]; then
        usage_error "Invalid --retry argument: '$MAX_ATTEMPTS'. Expected a positive integer."
    fi

}
while (($#)); do
    case "$1" in
        -m | --message)
            shift
            (($#)) || { usage >&2; usage_error "missing commit message after -m / --message."; }
            MESSAGE="$1"
            no_empty_message
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        --retry)
            shift
            (($#)) || usage_error "Missing value after --retry."
            MAX_ATTEMPTS="$1"
            validate_attempts
            ;;
        --)
            shift
            while (($#)); do FILES+=("$1"); shift; done
            break
          ;;
        -*)
            usage >&2
            usage_error "unknown option: $1"
            ;;
        *)
            FILES+=("$1")
            ;;
    esac
    shift
done

require_git_repo

stage() {
    git add -- "${FILES[@]}"
}

if [[ ${#FILES[@]} == 0 ]]; then
    usage_error "Must provide at least one file to add."
fi

if [[ -z "$MESSAGE" ]]; then
    stage
    exit 0
fi

stage
for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    before="$(git write-tree)" || die "Could not inspect staged files."
    
    if git commit -m "$MESSAGE"; then
        exit 0
    fi
    
    stage
    after="$(git write-tree)"

    if [[ "$before" == "$after" ]]; then
        die "Commit failed but no change in content - exiting."
    fi

    if [[ "$attempt" == "$MAX_ATTEMPTS" ]]; then
        break
    fi
    printf 'Commit failed; re-staging files and retrying (%d/%d)...\n' \
      "$((attempt + 1))" "$MAX_ATTEMPTS" >&2
done

die "commit failed after ${MAX_ATTEMPTS} attempts."