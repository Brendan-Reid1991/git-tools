#!/usr/bin/env bash
set -eo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
unset GIT_TOOLS_LIB_DIR

# Custom paths with spaces also verify that dispatch does not depend on cwd.
prefix="$sandbox/install prefix"
bindir="$prefix/tools"
sharedir="$prefix/support/gra"
make -s -C "$root" install PREFIX="$prefix" BINDIR="$bindir" SHAREDIR="$sharedir"
cd "$sandbox"

"$bindir/gra" --help
"$bindir/gra" add --help
"$bindir/gra" new --help
"$bindir/gra" setup --help
if "$bindir/gra" unknown-command; then
    echo "Unknown command unexpectedly succeeded" >&2
    exit 1
else
    test "$?" -eq 2
fi

# DESTDIR changes where files are copied, not the embedded runtime path.
make -s -C "$root" install PREFIX=/usr DESTDIR="$sandbox/stage"
test -x "$sandbox/stage/usr/bin/gra"
test -f "$sandbox/stage/usr/share/gra/commands/add.sh"
grep -Fx 'commands_dir="/usr/share/gra/commands"' "$sandbox/stage/usr/bin/gra"

# Uninstall must preserve unrelated files.
touch "$sharedir/commands/keep.txt"
make -s -C "$root" uninstall PREFIX="$prefix" BINDIR="$bindir" SHAREDIR="$sharedir"
test ! -e "$bindir/gra"
test ! -e "$sharedir/common.sh"
for file in "$root"/lib/commands/*.sh; do
    test ! -e "$sharedir/commands/${file##*/}"
done
test -f "$sharedir/commands/keep.txt"
echo "Smoke tests passed"
