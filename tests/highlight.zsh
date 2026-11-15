# tests/highlight.zsh -- checks the as-you-type highlighter in zshrc
#
# Runs inside an interactive zsh that has loaded zshrc, with the repo as the
# current folder (tests/smoke.sh does this). Each check feeds a command line
# to _highlight_line and compares the colored spans, written as [text]=color.
# Exits non-zero if any check fails.

typeset -i failures=0

spans() {
  BUFFER=$1
  _highlight_line
  local -a out
  local e s f c
  for e in $region_highlight; do
    s=${e%% *}; e=${e#* }; f=${e%% *}; c=${e#* }
    out+=("[${BUFFER[s+1,f]}]=$c")
  done
  print -r -- "${(j: :)out}"
}

check() {
  local got
  got=$(spans "$1")
  if [[ $got != "$2" ]]; then
    print -r -- "highlight: ${(q+)1}"
    print -r -- "  expected: $2"
    print -r -- "  got:      $got"
    (( failures++ ))
  fi
}

# An executable inside the home folder, for the ~/ path check
mkdir -p ~/bin && print '#!/bin/sh' > ~/bin/tool && chmod +x ~/bin/tool

# Commands, options, operators
check 'ls -la | grep foo'          '[ls]=fg=green [-la]=fg=cyan [|]=bold [grep]=fg=green'
check 'nosuchcmd arg'              '[nosuchcmd]=fg=red'
check 'echo "a b" # note'          '[echo]=fg=green ["a b"]=fg=yellow [# note]=fg=8'
check 'echo $HOME'                 '[echo]=fg=green [$HOME]=fg=magenta'
check 'FOO=1 nosuchcmd'            '[nosuchcmd]=fg=red'

# Shell syntax that starts a command must not show as an error
check '[[ -f x ]] && echo yes'     '[[[]=fg=green [-f]=fg=cyan [&&]=bold [echo]=fg=green'
check '(( 1 + 1 ))'                '[((]=fg=green'
check '! true'                     '[!]=fg=green [true]=fg=green'
check '{ ls }'                     '[{]=fg=green [ls]=fg=green'
check '(cd /tmp)'                  '[cd]=fg=green'
check 'if true; then ls; fi'       '[if]=fg=green [true]=fg=green [;]=bold [then]=fg=green [ls]=fg=green [;]=bold [fi]=fg=green'

# Paths to programs, and folder names (AUTO_CD runs cd)
check '/bin/ls'                    '[/bin/ls]=fg=green'
check '/no/such/program'           '[/no/such/program]=fg=red'
check './install.sh'               '[./install.sh]=fg=green'
check '~/bin/tool'                 '[~/bin/tool]=fg=green'
check 'tests'                      '[tests]=fg=green'

# A newline starts a new command, like ;
check $'ls\nnosuchcmd'             '[ls]=fg=green [nosuchcmd]=fg=red'

# Backslash-escaped quotes aren't strings
check 'echo \"hi there'            '[echo]=fg=green'

# Options to wrappers like sudo aren't commands
check 'sudo ls'                    '[sudo]=fg=green [ls]=fg=green'
check 'sudo -u root ls'            '[sudo]=fg=green [-u]=fg=cyan'

(( failures == 0 ))
