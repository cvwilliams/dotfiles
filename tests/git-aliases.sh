#!/usr/bin/env bash
# tests/git-aliases.sh -- checks the `git cleanup` and `git recent` aliases
#
# Run with HOME set to a throwaway folder where install.sh has linked
# gitconfig (tests/smoke.sh does this). Exits non-zero on any failure.
set -euo pipefail

export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
failures=0
fail() { echo "git aliases: $*" >&2; failures=$((failures + 1)); }
q() { git "$@" >/dev/null 2>&1; }

repo="$HOME/cleanup-repo"
mkdir -p "$repo" && cd "$repo"
q init
echo one > file.txt; q add file.txt; q commit -m one
q init --bare "$HOME/cleanup-origin.git"
q remote add origin "$HOME/cleanup-origin.git"
q push -u origin main
q remote set-head origin main

# merged-normal: merged into main with a regular merge commit
q switch -c merged-normal; echo a > a.txt; q add a.txt; q commit -m a
q switch main; q merge --no-ff -m "merge a" merged-normal

# squashed: two commits, merged as one squash commit (like GitHub's button)
q switch -c squashed; echo b > b.txt; q add b.txt; q commit -m b1
echo b2 >> b.txt; q commit -am b2
q switch main; q merge --squash squashed; q commit -m "squash b"

# unmerged: has work that isn't in main
q switch -c unmerged; echo c > c.txt; q add c.txt; q commit -m c
q switch main
q push origin main

# current: merged, but checked out, so it must be kept
q switch -c current

branches() { git for-each-ref --format='%(refname:short)' refs/heads/ | sort | tr '\n' ' '; }

# -n lists exactly the two merged branches and deletes nothing
out=$(git cleanup -n)
[[ "$out" == *merged-normal* && "$out" == *squashed* ]] || fail "-n didn't list both merged branches: $out"
[[ "$out" != *unmerged* && "$out" != *"  current "* ]]  || fail "-n listed a branch it must keep: $out"
[[ "$(branches)" == "current main merged-normal squashed unmerged " ]] || fail "-n deleted something: $(branches)"

# Without a terminal to answer the question, nothing is deleted
out=$(git cleanup </dev/null 2>&1 || true)
[[ "$out" == *"Nothing deleted."* ]] || fail "unanswered question didn't stop it: $out"
[[ "$(branches)" == "current main merged-normal squashed unmerged " ]] || fail "deleted without an answer: $(branches)"

# -y deletes the merged branches and keeps the rest
out=$(git cleanup -y)
[[ "$out" == *"deleted merged-normal"* && "$out" == *"deleted squashed"* ]] || fail "-y output: $out"
[[ "$(branches)" == "current main unmerged " ]] || fail "-y left the wrong branches: $(branches)"

# Running again finds nothing
out=$(git cleanup -y)
[[ "$out" == "Nothing to clean up"* ]] || fail "second run: $out"

# Bad option
git cleanup --bogus >/dev/null 2>&1 && fail "--bogus was accepted"

# git recent lists branches, most recent first
out=$(git recent)
[[ "$(head -1 <<<"$out")" == *current* ]] || fail "git recent first line: $(head -1 <<<"$out")"
[[ "$out" == *unmerged* && "$out" == *main* ]] || fail "git recent missing branches: $out"

[[ $failures -eq 0 ]]
