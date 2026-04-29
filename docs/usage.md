# Usage

## `git superadd`

```bash
git superadd path/to/file -m "feat: update helper"
git superadd -m "chore: snapshot all local changes"
```

- Accepts files and `-m/--message` in any order.
- If no files are provided, stages all changes with `git add -A`.

## `git newbranch`

```bash
git newbranch feature/my-branch
```

- Creates and switches to the given branch.

## `git superpush`

```bash
git superpush
```

- Pushes normally when upstream exists.
- Sets upstream to `origin/<current-branch>` on first push.
