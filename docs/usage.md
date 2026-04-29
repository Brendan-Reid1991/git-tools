# Usage

## `git superadd`

```
git superadd [options] [--] [<file>...] -m <message>
```

Stages the given files (or, with `-a/--all`, every change) and commits
them. If a pre-commit hook modifies tracked files, the hook-modified
files are re-staged and the commit is retried up to `--max-attempts`
times. The retry loop bails immediately if nothing changed since the
previous attempt — so a hook that always fails for a real reason
produces one error, not five.

Options:

- `-m, --message <msg>` — commit message (required).
- `-a, --all` — stage all changes (`git add -A`) when no files are passed.
- `--max-attempts N` — maximum commit attempts (default: 3).
- `-h, --help` — show help.

Examples:

```bash
git superadd src/main.sh -m "fix: tighten argument parsing"
git superadd -a -m "chore: snapshot all local changes"
git superadd path/to/file -m "feat: x" --max-attempts 5
```

`git superadd -m "msg"` with no files and no `-a/--all` is rejected — it
used to silently `git add -A`, which was a footgun.

## `git newbranch`

```
git newbranch <name> [<base>]
```

Creates and switches to a new branch, optionally from `<base>`.

Examples:

```bash
git newbranch feature/parser
git newbranch hotfix/login origin/main
```

## `git superpush`

```
git superpush [options]
```

Pushes the current branch. On first push, sets upstream to
`<remote>/<branch>`, where `<remote>` is resolved in this order:

1. `branch.<name>.pushRemote`
2. `remote.pushDefault`
3. The upstream's remote (if already configured).
4. `origin` (if it exists).

If none of those is set, the command exits with a clear error rather
than guessing.

Options:

- `-f, --force` — `--force-with-lease --force-if-includes` (safe force).
- `-n, --dry-run` — passthrough to `git push`.
- `--no-verify` — passthrough to `git push`.
- `-h, --help` — show help.

## Exit codes

- `0` — success.
- `1` — generic runtime error (not in a repo, no remote, push failed, …).
- `2` — usage / argument error.

## Environment

- `GIT_TOOLS_LIB_DIR` — override the directory used to locate
  `git-tools-common.sh`. Useful for testing against an uninstalled checkout.
