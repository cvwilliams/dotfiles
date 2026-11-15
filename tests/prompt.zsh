# tests/prompt.zsh -- checks the git part of the prompt in zshrc
#
# Runs inside an interactive zsh that has loaded zshrc, with HOME set to a
# throwaway folder (tests/smoke.sh does this). Builds small git repos and
# compares the visible text of the git segment. Exits non-zero on any failure.

typeset -i failures=0
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com

# The git segment as it would appear on screen, without color codes
segment() {
  _prompt_git
  print -rn -- "${(%)_prompt_git_msg}" | sed -E $'s/\x1b\\[[0-9;]*m//g'
}

check() {
  local got
  got=$(segment)
  if [[ $got != "$2" ]]; then
    print -r -- "prompt ($1):"
    print -r -- "  expected: '$2'"
    print -r -- "  got:      '$got'"
    (( failures++ ))
  fi
}

q() { git "$@" >/dev/null 2>&1; }

cd ~ || exit 1
check "outside a repo" ""

# A repo with one commit on main, pushed to a local "origin"
mkdir -p ~/repo && cd ~/repo || exit 1
q init; print one > file.txt; q add file.txt; q commit -m one
q init --bare ~/origin.git; q remote add origin ~/origin.git; q push -u origin main
check "clean"                " 🌿 main"

print untracked > new.txt
check "untracked only"       " 🌿 main"
command rm -f new.txt   # not the interactive rm -i alias

print two >> file.txt
check "unstaged change"      " 🌿 main*"
q add file.txt
check "staged change"        " 🌿 main+"
print three >> file.txt
check "staged and unstaged"  " 🌿 main*+"
q commit -am two
check "ahead of upstream"    " 🌿 main ↑1"

# Another clone pushes a commit, so this one is also behind
q clone ~/origin.git ~/other
( cd ~/other && print other > other.txt && q add other.txt && q commit -m other && q push )
q fetch
check "ahead and behind"     " 🌿 main ↑1↓1"
q reset --hard origin/main
q reset --hard HEAD~1
check "behind only"          " 🌿 main ↓1"
q merge --ff-only origin/main

mkdir -p sub && cd sub || exit 1
check "in a subfolder"       " 🌿 main"
cd ..

q switch -c 'feat%x'
check "branch name with %"   " 🌿 feat%x"
q switch main

q checkout --detach HEAD
check "detached HEAD"        " 🌿 $(git rev-parse --short=7 HEAD)"
q switch main

# A merge stopped by a conflict
q switch -c side; print side > file.txt; q commit -am side; q switch main
print mainside > file.txt; q commit -am mainside
q merge side
check "merge conflict"       " 🌿 main|merge* ↑1"   # mainside isn't pushed yet
q merge --abort

# A rebase stopped by the same conflict shows the branch being rebased
q switch side
q rebase main
check "rebase conflict"      " 🌿 side|rebase*"
q rebase --abort
q switch main

(( failures == 0 ))
