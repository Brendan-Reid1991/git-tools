# git-tools

Small Bash helpers exposed as Git subcommands. This repo exists primarily for me to avoid setting up my git config on a new machine each time.

## Included commands

### `git superadd`

Stage files and commit. If a pre-commit hook modifies tracked files, the
modifications are re-staged and the commit is retried automatically.

**Why?** Having to manually re-stage and re-commit after a pre-commit
hook fails and performs edits in-place is tedious. This removes that tedium by automatically retrying the add/commit loop, while still failing fast when a hook complains for a real reason.

### `git newbranch`

Create and switch to a new branch, optionally from a specific base branch.

**Why?** Personally, I find both `git checkout -b` and `git switch -c` less intuitive than `git newbranch`.

### `git superpush`

Push the current branch, resolving the push remote from config and
setting upstream automatically on first push.


**Why?** I usually forget to set my upstreams prior to pushing a new branch for the first time.
This one was written before I discovered that the git config can do this anyway.
```bash
git config --global push.autoSetupRemote true
git config --global push.default current
```

Leaving it here as a monument to man's arrogance.



## Install

```bash
make install
```

By default this installs:

- executables to `$(PREFIX)/bin` (default: `~/.local/bin`),
- the shared library to `$(PREFIX)/share/git-tools/git-tools-common.sh`.

The lib path is baked into each installed script at install time, so the
binaries on `PATH` have no fallback lookup logic.

Override the install location with `PREFIX`, `BINDIR`, `SHAREDIR`, or
`DESTDIR` (for staged installs):

```bash
make install PREFIX=/usr/local                # system-wide
make install DESTDIR=/tmp/stage PREFIX=/usr   # packaging
```

Make sure `$(PREFIX)/bin` is on your `PATH`.

## Uninstall

```bash
make uninstall
```

Removes only the files this Makefile installed.

## Verify setup

```bash
make doctor
```

## Develop

```bash
make test    # run smoke tests against an installed sandbox prefix
make lint    # run shellcheck
make help    # show variables and targets
```

## Quick examples

```bash
git superadd src/main.sh -m "fix: tighten argument parsing"
git superadd -a -m "chore: snapshot all local changes"

git newbranch feature/parser
git newbranch hotfix/login origin/main

git superpush
git superpush --force --no-verify
```

See [`docs/usage.md`](docs/usage.md) for full flag documentation.
