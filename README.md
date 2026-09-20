# GRA - Git Replacer, Almost

[![CI](https://github.com/Brendan-Reid1991/git-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/Brendan-Reid1991/git-tools/actions/workflows/ci.yml)

Originally this package extended the `git` namespace to save me some time in my day-to-day working. Now I'm targeting a full CLI to ~ kind of ~ replace `git.

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

See [`docs/usage.md`](docs/usage.md) for full flag documentation.
