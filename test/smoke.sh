#!/usr/bin/env bash
set -euo pipefail

# Smoke tests for git-tools. Exercises positive paths against real repos
# (created in temp dirs) and a few important negative paths.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0
CURRENT_TEST=""

pass() { printf '  ok: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

start_test() {
  CURRENT_TEST="$1"
  printf '\n== %s ==\n' "$CURRENT_TEST"
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label (expected: '$expected', got: '$actual')"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (expected to contain '$needle', got: $haystack)"
  fi
}

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label (expected exit $expected, got $actual)"
  fi
}

# --- environment setup ---------------------------------------------------

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

PREFIX_DIR="$TMPROOT/prefix"
mkdir -p "$PREFIX_DIR"

new_workdir() {
  mktemp -d "$TMPROOT/work.XXXXXX"
}

new_repo() {
  local d
  d="$(new_workdir)"
  (
    cd "$d"
    git init -q -b main
    git config user.email tester@example.com
    git config user.name  Tester
  )
  printf '%s\n' "$d"
}

# Install into a sandboxed prefix so we exercise the install-time bootstrap
# substitution.
make -C "$ROOT_DIR" PREFIX="$PREFIX_DIR" install >/dev/null
export PATH="$PREFIX_DIR/bin:$PATH"

# --- bootstrap was substituted -------------------------------------------

start_test "install-time bootstrap substitution"
for s in git-superadd git-newbranch git-superpush; do
  if grep -q '# git-tools-bootstrap:begin' "$PREFIX_DIR/bin/$s"; then
    fail "$s still contains dev-mode bootstrap markers"
  else
    pass "$s bootstrap was substituted"
  fi
  if ! grep -q "$PREFIX_DIR/share/git-tools" "$PREFIX_DIR/bin/$s"; then
    fail "$s does not reference installed lib path"
  else
    pass "$s references installed lib path"
  fi
done

# --- not-in-repo error path ----------------------------------------------

start_test "not-in-repo error"
NON_REPO="$(new_workdir)"
out="$(cd "$NON_REPO" && git-superadd -m m -a 2>&1 || true)"
assert_contains "$out" "not inside a Git repository." "git-superadd rejects non-repo"
out="$(cd "$NON_REPO" && git-newbranch some-branch 2>&1 || true)"
assert_contains "$out" "not inside a Git repository." "git-newbranch rejects non-repo"
out="$(cd "$NON_REPO" && git-superpush 2>&1 || true)"
assert_contains "$out" "not inside a Git repository." "git-superpush rejects non-repo"

# --- --help on each tool -------------------------------------------------

start_test "--help"
for s in git-superadd git-newbranch git-superpush; do
  out="$("$s" --help 2>&1)"
  rc=$?
  assert_exit 0 "$rc" "$s --help exits 0"
  pretty="${s/git-/git }"
  assert_contains "$out" "Usage: $pretty" "$s --help prints usage"
done

# --- git-superadd: positive path ----------------------------------------

start_test "git-superadd: explicit file"
REPO="$(new_repo)"
(
  cd "$REPO"
  echo hello > a.txt
  git-superadd a.txt -m "feat: add a"
)
msg="$(cd "$REPO" && git log -1 --pretty=%s)"
assert_eq "feat: add a" "$msg" "commit message recorded"

start_test "git-superadd: -a stages everything"
REPO="$(new_repo)"
(
  cd "$REPO"
  echo one > one.txt; echo two > two.txt
  git-superadd -a -m "chore: snapshot"
)
files="$(cd "$REPO" && git ls-tree -r --name-only HEAD | sort | tr '\n' ' ')"
assert_eq "one.txt two.txt " "$files" "all files committed via -a"

start_test "git-superadd: requires -a or files"
REPO="$(new_repo)"
out="$(cd "$REPO" && git-superadd -m "msg" 2>&1 || true)"
assert_contains "$out" "no files specified" "rejects bare -m"

start_test "git-superadd: requires -m"
REPO="$(new_repo)"
(cd "$REPO" && echo x > f.txt)
out="$(cd "$REPO" && git-superadd f.txt 2>&1 || true)"
assert_contains "$out" "commit message is required" "rejects missing -m"

start_test "git-superadd: pre-commit hook re-stages modified file"
REPO="$(new_repo)"
(
  cd "$REPO"
  cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
# Simulate a formatter that rewrites a tracked file once on first run.
set -euo pipefail
state_file=".git/hook-state"
if [[ ! -f "$state_file" ]]; then
  echo reformatted > a.txt
  echo done > "$state_file"
  exit 1
fi
exit 0
HOOK
  chmod +x .git/hooks/pre-commit
  echo original > a.txt
  git-superadd a.txt -m "feat: add a after hook"
)
content="$(cd "$REPO" && git show HEAD:a.txt)"
assert_eq "reformatted" "$content" "hook-modified content was committed"

start_test "git-superadd: bails when hook keeps failing without changes"
REPO="$(new_repo)"
(
  cd "$REPO"
  cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
echo "always rejecting" >&2
exit 1
HOOK
  chmod +x .git/hooks/pre-commit
  echo x > a.txt
)
out="$(cd "$REPO" && git-superadd a.txt -m "should fail" 2>&1 || true)"
assert_contains "$out" "no files changed since last attempt" "no-progress bail message"
# Should bail after at most 2 attempts (initial + one retry that produces no change).
attempts="$(printf '%s\n' "$out" | grep -c "retrying" || true)"
if (( attempts <= 1 )); then
  pass "did not run all 3 attempts when no progress (saw $attempts retry messages)"
else
  fail "ran $attempts retries despite no progress"
fi

# --- git-newbranch -------------------------------------------------------

start_test "git-newbranch: basic"
REPO="$(new_repo)"
(
  cd "$REPO"
  echo x > f.txt
  git add f.txt && git commit -q -m initial
  git-newbranch feature/test
)
b="$(cd "$REPO" && git rev-parse --abbrev-ref HEAD)"
assert_eq "feature/test" "$b" "switched to new branch"

start_test "git-newbranch: with explicit base"
REPO="$(new_repo)"
(
  cd "$REPO"
  echo x > f.txt && git add f.txt && git commit -q -m initial
  git switch -q -c base
  echo y > g.txt && git add g.txt && git commit -q -m second
  git switch -q main
  git-newbranch off-base base
)
parent_sha="$(cd "$REPO" && git rev-parse off-base)"
base_sha="$(cd "$REPO"   && git rev-parse base)"
assert_eq "$base_sha" "$parent_sha" "branched from explicit base"

start_test "git-newbranch: rejects too many args"
REPO="$(new_repo)"
(cd "$REPO" && echo x > f.txt && git add f.txt && git commit -q -m initial)
out="$(cd "$REPO" && git-newbranch a b c 2>&1 || true)"
assert_contains "$out" "too many positional arguments" "rejects 3+ args"

# --- git-superpush -------------------------------------------------------

start_test "git-superpush: detached HEAD"
REPO="$(new_repo)"
(
  cd "$REPO"
  echo x > f.txt && git add f.txt && git commit -q -m initial
  git checkout -q --detach HEAD
)
out="$(cd "$REPO" && git-superpush 2>&1 || true)"
assert_contains "$out" "detached HEAD" "detects detached HEAD"

start_test "git-superpush: no remote configured"
REPO="$(new_repo)"
(cd "$REPO" && echo x > f.txt && git add f.txt && git commit -q -m initial)
out="$(cd "$REPO" && git-superpush 2>&1 || true)"
assert_contains "$out" "no push remote configured" "errors when no remote"

start_test "git-superpush: first push sets upstream"
REPO="$(new_repo)"
BARE="$(new_workdir)/bare.git"
git init -q --bare "$BARE"
(
  cd "$REPO"
  echo x > f.txt && git add f.txt && git commit -q -m initial
  git remote add origin "$BARE"
  git-superpush
)
upstream="$(cd "$REPO" && git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
assert_eq "origin/main" "$upstream" "upstream set on first push"

start_test "git-superpush: second push is plain"
(
  cd "$REPO"
  echo y >> f.txt && git add f.txt && git commit -q -m second
  git-superpush --dry-run >/dev/null
  git-superpush
)
remote_head="$(git --git-dir="$BARE" rev-parse main)"
local_head="$(cd "$REPO" && git rev-parse main)"
assert_eq "$local_head" "$remote_head" "remote received second push"

start_test "git-superpush: respects branch.<name>.pushRemote"
REPO="$(new_repo)"
BARE_DEFAULT="$(new_workdir)/default.git"
BARE_OVERRIDE="$(new_workdir)/override.git"
git init -q --bare "$BARE_DEFAULT"
git init -q --bare "$BARE_OVERRIDE"
(
  cd "$REPO"
  echo x > f.txt && git add f.txt && git commit -q -m initial
  git remote add origin    "$BARE_DEFAULT"
  git remote add overrider "$BARE_OVERRIDE"
  git config "branch.main.pushRemote" overrider
  git-superpush
)
override_head="$(git --git-dir="$BARE_OVERRIDE" rev-parse --verify main 2>/dev/null || echo MISSING)"
default_head="$(git  --git-dir="$BARE_DEFAULT"  rev-parse --verify main 2>/dev/null || echo MISSING)"
local_head="$(cd "$REPO" && git rev-parse --verify main)"
assert_eq "$local_head" "$override_head" "pushed to pushRemote override"
assert_eq "MISSING"     "$default_head"  "did not push to origin"

# --- uninstall cleanly ---------------------------------------------------

start_test "uninstall removes only owned files"
touch "$PREFIX_DIR/bin/not-ours.sh"
make -C "$ROOT_DIR" PREFIX="$PREFIX_DIR" uninstall >/dev/null
if [[ -f "$PREFIX_DIR/bin/not-ours.sh" ]]; then
  pass "stranger file in bin/ untouched"
else
  fail "uninstall removed an unrelated file"
fi
for s in git-superadd git-newbranch git-superpush; do
  if [[ -f "$PREFIX_DIR/bin/$s" ]]; then
    fail "$s still installed after uninstall"
  fi
done
if [[ -f "$PREFIX_DIR/share/git-tools/git-tools-common.sh" ]]; then
  fail "library still installed after uninstall"
fi
pass "all owned files removed"

# --- summary -------------------------------------------------------------

printf '\n%d passed, %d failed.\n' "$PASS" "$FAIL"
((FAIL == 0))
