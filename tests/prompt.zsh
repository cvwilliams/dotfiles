# tests/prompt.zsh -- checks the prompt in zshrc
#
# Runs inside an interactive zsh that has loaded zshrc, with HOME set to a
# throwaway folder (tests/smoke.sh does this). Builds small git repos and
# compares the visible text of each prompt part. Exits non-zero on any failure.

typeset -i failures=0
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com

# A prompt string as it would appear on screen, without color codes
visible() { print -rn -- "${(%)1}" | sed -E $'s/\x1b\\[[0-9;]*m//g'; }

expect() {   # expect <description> <expected> <got>
  if [[ $3 != "$2" ]]; then
    print -r -- "prompt ($1):"
    print -r -- "  expected: '$2'"
    print -r -- "  got:      '$3'"
    (( failures++ ))
  fi
}

check() {    # check <description> <expected git segment> [<expected folder>]
  _prompt_git
  expect "$1" "$2" "$(visible "$_prompt_git_msg")"
  if (( $# > 2 )); then
    _prompt_dir
    expect "$1, folder" "$3" "$(visible "$_prompt_dir_msg")"
  fi
}

q() { git "$@" >/dev/null 2>&1; }

# --- Git segment and folder ---------------------------------------------------
cd ~ || exit 1
check "outside a repo" "" "~"
mkdir -p ~/a/b/c/d && cd ~/a/b/c/d || exit 1
check "deep outside a repo" "" "…/b/c/d"

# A repo with one commit on main, pushed to a local "origin"
mkdir -p ~/repo && cd ~/repo || exit 1
q init; print one > file.txt; q add file.txt; q commit -m one
q init --bare ~/origin.git; q remote add origin ~/origin.git; q push -u origin main
check "clean"                " 🌿 main"           "repo"

print untracked > new.txt
check "untracked file"       " 🌿 main?"
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

print stash1 >> file.txt; q stash
print stash2 >> file.txt; q stash
check "two stashes"          " 🌿 main \$2"
q stash clear

mkdir -p sub/deeper/still && cd sub || exit 1
check "in a subfolder"       " 🌿 main"           "repo/sub"
cd deeper/still || exit 1
check "deep in the repo"     " 🌿 main"           "repo/…/deeper/still"
cd ~/repo || exit 1

q switch -c 'feat%x'
check "branch name with %"   " 🌿 feat%x"
q switch main

q checkout --detach HEAD
check "detached HEAD"        " 🌿 $(git rev-parse --short=7 HEAD)"
q switch main

# A merge stopped by a conflict: = marks conflicted files
q switch -c side; print side > file.txt; q commit -am side; q switch main
print mainside > file.txt; q commit -am mainside
q merge side
check "merge conflict"       " 🌿 main|merge= ↑1"   # mainside isn't pushed yet
q merge --abort

# A rebase stopped by the same conflict shows the branch and its progress
q switch side
q rebase main
check "rebase conflict"      " 🌿 side|rebase 1/1="
q rebase --abort
q switch main

# --- Exit status, with signal names ---------------------------------------------
for code_label in "0:" "1:✘ 1 " "127:✘ 127 " "130:✘ INT " "137:✘ KILL "; do
  _prompt_status ${code_label%%:*}
  expect "status ${code_label%%:*}" "${code_label#*:}" "$(visible "$_prompt_status_msg")"
done

# --- Nested shell level -----------------------------------------------------------
SHLVL=1 _prompt_extra; expect "shell level 1" "" "$(visible "$_prompt_extra_msg")"
SHLVL=3 _prompt_extra; expect "shell level 3" " ↳3" "$(visible "$_prompt_extra_msg")"

# --- Notification after a long command ------------------------------------------------
# Stand-ins for lsappinfo (reports $FRONT as the front app) and osascript (records)
mkdir -p ~/stub
print -r -- '#!/bin/sh
case "$1" in front) echo "ASN:0x0-0x1:" ;; *) echo "\"LSDisplayName\"=\"$FRONT\"" ;; esac' > ~/stub/lsappinfo
print -r -- '#!/bin/sh
shift 6; echo "$*" >> "$HOME/notified.txt"' > ~/stub/osascript
chmod +x ~/stub/*
path=(~/stub $path)

command rm -f ~/notified.txt
FRONT=Safari TERM_PROGRAM=Apple_Terminal _prompt_notify 95 0 "make build"
sleep 1
expect "notify when Terminal is in the background" \
  "make build finished after 1m 35s ✓ Terminal" "$(cat ~/notified.txt 2>/dev/null)"
command rm -f ~/notified.txt
FRONT=Terminal TERM_PROGRAM=Apple_Terminal _prompt_notify 95 1 "make build"
sleep 1
expect "no notification while Terminal is in front" "" "$(cat ~/notified.txt 2>/dev/null)"
path=(${path:#$HOME/stub})

# --- Transient prompt -----------------------------------------------------------------
# In a real interactive shell, once a command is entered its prompt is redrawn
# as just "❯ command", without the folder and git parts
# (script(1) records what the screen receives while keys are typed into the shell)
command rm -f ~/transient.txt
( sleep 2; print -n 'echo transient-ok\r'; sleep 2; print -n 'exit\r'; sleep 1 ) \
  | ( cd ~/repo && TERM=xterm-256color ZDOTDIR=$HOME script -q ~/transient.txt zsh -i >/dev/null 2>&1 )
out=$(sed -E $'s/\x1b\\[[0-9;?]*[A-Za-z]//g' ~/transient.txt 2>/dev/null | tr '\r' '\n')
lines=("${(@f)out}")
(( ${lines[(Ie)❯ echo transient-ok]} )) \
  || { print -r -- "prompt (transient): earlier prompt not collapsed to '❯ command':"
       print -r -- "$out" | tail -8; (( failures++ )) }

(( failures == 0 ))
