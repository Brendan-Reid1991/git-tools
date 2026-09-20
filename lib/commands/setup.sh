#!/usr/bin/env bash

set -e

__here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=../common.sh
source "${GIT_TOOLS_LIB_DIR:-${__here}/..}/common.sh"
unset __here

for arg in "$@"; do
    case "$arg" in 
        -h | --help)
            printf "Run once to set up global git settings.\n"
            exit 0 ;;
        *)
            usage_error "Unknown option $arg"
            ;;
    esac
done

git config --global fetch.prune true

git config --global merge.conflictStyle zdiff3

git config --global rerere.enabled true

git config --global branch.sort -committerdate

git config --global push.autoSetupRemote true

git config --global push.default simple

git config --global init.defaultBranch main