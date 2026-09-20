#!/usr/bin/env bash
set -eo pipefail

exec git log -s --format='%h : %s (%ad)' --date=format:'%Y-%m-%d %H:%M:%S' -n "${1:-5}"