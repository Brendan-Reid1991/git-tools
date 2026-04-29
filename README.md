# git-tools

Small Bash helpers exposed as Git subcommands.

## Included commands

- `git superadd`: stage files and commit with a message.
- `git newbranch`: create and switch to a new branch.
- `git superpush`: push current branch, setting upstream on first push.

## Install

```bash
make install
```

By default, scripts install to `~/.local/bin`. Ensure that directory is on your `PATH`.

## Uninstall

```bash
make uninstall
```

## Verify setup

```bash
make doctor
```

## Quick examples

```bash
git superadd src/main.sh -m "fix: tighten argument parsing"
git newbranch feature/better-error-messages
git superpush
```
