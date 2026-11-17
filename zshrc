# zshrc -- minimal, plugin-free zsh config for macOS
# Sections: 1 History & shell options, 2 Completion, 3 Prompt, 4 Error handlers,
# 5 Keybindings, functions & aliases, 6 Light/dark Terminal profile, 7 Local overrides.

# ==============================================================================
# 1. HISTORY & SHELL OPTIONS
# ==============================================================================
HISTFILE="$HOME/.zsh_history"   # Shell settings, not exported: other programs don't need them
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY          # Share history across sessions
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates when file is full
setopt HIST_IGNORE_DUPS       # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove old duplicates on new entries
setopt HIST_FIND_NO_DUPS      # Filter duplicates in history search
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicates to file
setopt HIST_REDUCE_BLANKS     # Trim blank spaces
HISTORY_IGNORE='(ls|ll|la|cd|pwd|exit|clear|reload)'  # Don't save these trivial commands

setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push directory stack on cd
setopt PUSHD_IGNORE_DUPS      # Avoid duplicates in stack
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell

# Clean, text-only auto-correct prompt
setopt CORRECT
SPROMPT="%F{yellow}zsh: correct '%R' to '%r' [nyae]? %f"

# ==============================================================================
# 2. BUILT-IN AUTOCOMPLETION
# ==============================================================================
# Rebuild the completion cache at most once a day; otherwise load it as-is (-C).
# The (#q...) glob qualifier needs EXTENDED_GLOB, enabled just for this check.
autoload -U compinit
() {
  setopt local_options extended_glob
  if [[ -n ~/.zcompdump(#qN.mh+24) || ! -f ~/.zcompdump ]]; then
    compinit
  else
    compinit -C
  fi
  # Keep a compiled copy of the cache, which zsh loads faster; recompile only
  # when the cache has changed, in the background so startup doesn't wait
  if [[ ~/.zcompdump -nt ~/.zcompdump.zwc || ! -s ~/.zcompdump.zwc ]]; then
    zcompile ~/.zcompdump &!
  fi
}

zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- No matches found --%f'
zstyle ':completion:*:default' list-colors ''   # Default file-type colors (macOS ls doesn't set LS_COLORS)

# ==============================================================================
# 3. MINIMALIST SINGLE-LINE PROMPT & TIMER
# ==============================================================================
#   repo/sub 🌿 main|rebase 2/5=*+? ↑1↓2 $3 (venv) ⚙1 🔒 ↳2 ✘ INT ❯
# Each part appears only when it applies. Parts are worked out once per prompt
# by precmd hooks rather than on every redraw, and only the git part runs a
# command.
autoload -U colors && colors

# --- Git segment ----------------------------------------------------------------
#   🌿 branch|action   = conflicts  * unstaged  + staged  ? untracked
#   ↑ahead ↓behind the upstream     $N stashes
# One `git status` call per prompt (about 10 ms), instead of zsh's vcs_info,
# which runs several git commands (about 60 ms). Outside a repo no git command
# runs at all, because the .git folder is found by walking up from $PWD.
typeset -g _prompt_git_msg="" _prompt_repo_root=""
_prompt_git() {
  _prompt_git_msg="" _prompt_repo_root=""

  # Find the .git folder (or, in a worktree/submodule, the .git file pointing to it)
  local dir=$PWD gitdir=""
  while :; do
    if [[ -d $dir/.git ]]; then
      gitdir=$dir/.git; break
    elif [[ -f $dir/.git ]]; then
      gitdir=$(<$dir/.git); gitdir=${gitdir#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
      break
    fi
    [[ $dir == / ]] && return
    dir=${dir:h}
  done
  _prompt_repo_root=$dir

  # --porcelain=v2 gives branch, upstream ahead/behind and per-file states in
  # one call. GIT_OPTIONAL_LOCKS=0 keeps it from locking the index while other
  # git commands run.
  local -a lines
  lines=("${(@f)$(GIT_OPTIONAL_LOCKS=0 git status --porcelain=v2 --branch 2>/dev/null)}") \
    || return

  local line oid="" branch="" action="" ab="" stash=""
  local conflicts="" unstaged="" staged="" untracked=""
  local -i ahead=0 behind=0
  for line in $lines; do
    case $line in
      '# branch.oid '*)  oid=${line#\# branch.oid } ;;
      '# branch.head '*) branch=${line#\# branch.head } ;;
      '# branch.ab '*)   ahead=${${line#\# branch.ab +}%% *}; behind=${line##* -} ;;
      # Changed files: "1 XY ..." / "2 XY ..." where X is staged and Y unstaged
      # ("." means no change); "u ..." is a merge conflict; "? ..." untracked
      [12]' '*)
        [[ ${line[3]} != . ]] && staged='%F{green}+%f'
        [[ ${line[4]} != . ]] && unstaged='%F{red}*%f'
        ;;
      'u '*) conflicts='%F{red}=%f' ;;
      '? '*) untracked='%F{yellow}?%f' ;;
    esac
  done

  # In-progress operations, from marker files git leaves in .git
  if [[ -d $gitdir/rebase-merge || -d $gitdir/rebase-apply ]]; then
    action=rebase
    # During a rebase HEAD is detached; show the branch being rebased instead
    local f step="" total=""
    for f in $gitdir/rebase-{merge,apply}/head-name(N); do
      branch=${$(<$f)#refs/heads/}
    done
    # Progress, e.g. "rebase 2/5" (rebase-merge keeps msgnum/end, rebase-apply next/last)
    if [[ -f $gitdir/rebase-merge/msgnum ]]; then
      step=$(<$gitdir/rebase-merge/msgnum); total=$(<$gitdir/rebase-merge/end)
    elif [[ -f $gitdir/rebase-apply/next ]]; then
      step=$(<$gitdir/rebase-apply/next); total=$(<$gitdir/rebase-apply/last)
    fi
    [[ -n $step && -n $total ]] && action+=" $step/$total"
  elif [[ -f $gitdir/MERGE_HEAD ]]; then       action=merge
  elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then action=cherry-pick
  elif [[ -f $gitdir/REVERT_HEAD ]]; then      action=revert
  elif [[ -f $gitdir/BISECT_LOG ]]; then       action=bisect
  fi

  # Stashes, counted from git's stash log (shared by all worktrees of a repo)
  local common=$gitdir
  if [[ -f $gitdir/commondir ]]; then
    common=$(<$gitdir/commondir)
    [[ $common == /* ]] || common=$gitdir/$common
  fi
  [[ -s $common/logs/refs/stash ]] \
    && stash=" %F{yellow}\$${#${(f)"$(<$common/logs/refs/stash)"}}%f"

  [[ $branch == '(detached)' ]] && branch=${oid[1,7]}
  (( ahead ))  && ab+="↑$ahead"
  (( behind )) && ab+="↓$behind"

  # % doubled so a % in a branch name isn't read as prompt formatting
  _prompt_git_msg=" %F{magenta}🌿 ${branch//\%/%%}${action:+|$action}%f"
  _prompt_git_msg+="${conflicts}${unstaged}${staged}${untracked}"
  [[ -n $ab ]] && _prompt_git_msg+=" %F{magenta}$ab%f"
  _prompt_git_msg+=$stash
  return 0
}

# --- Folder -----------------------------------------------------------------------
# Inside a repo the path starts at the repo (dotfiles/tests, dotfiles/…/b/c);
# elsewhere it's the usual ~/path, shortened to …/last/three
typeset -g _prompt_dir_msg=""
_prompt_dir() {
  if [[ -n $_prompt_repo_root && $_prompt_repo_root != $HOME && $_prompt_repo_root != / ]]; then
    local rel=${PWD#$_prompt_repo_root}
    local -a parts=(${(s:/:)rel})
    (( ${#parts} > 2 )) && rel="/…/${parts[-2]}/${parts[-1]}"
    local shown=${_prompt_repo_root:t}$rel
    _prompt_dir_msg=${shown//\%/%%}
  else
    _prompt_dir_msg='%(4~|…/%3~|%~)'
  fi
}

# --- Exit status --------------------------------------------------------------------
# After a failure: ✘ and the exit code, or the signal's name when a signal ended
# the command (130 → INT for Ctrl-C, 137 → KILL, 143 → TERM)
typeset -g _prompt_status_msg=""
_prompt_status() {
  local -i code=${1:-0}
  local label=$code
  (( code > 128 && code - 127 <= ${#signals} )) && label=$signals[code-127]
  _prompt_status_msg=""
  (( code )) && _prompt_status_msg="%F{red}✘ $label%f "
  return 0
}

# --- Command timer and long-command notification --------------------------------------
# Commands taking 3 seconds or more print their run time. Ones taking
# PROMPT_NOTIFY_SECONDS (default 30) or more also post a macOS notification if
# the terminal isn't the front app, i.e. you switched away while waiting.
# Set PROMPT_NOTIFY_SECONDS=0 in ~/.zshrc.local to turn notifications off.
: ${PROMPT_NOTIFY_SECONDS:=30}

_prompt_duration() {   # 125 -> "2m 5s"
  local -i t=$1 h m s
  (( h = t / 3600, m = t % 3600 / 60, s = t % 60 ))
  if (( h )); then print -r -- "${h}h ${m}m ${s}s"
  elif (( m )); then print -r -- "${m}m ${s}s"
  else print -r -- "${s}s"; fi
}

_prompt_notify() {     # _prompt_notify <seconds> <exit status> <command>
  [[ $OSTYPE == darwin* ]] || return 0
  local app front mark='✓'
  case $TERM_PROGRAM in
    Apple_Terminal) app=Terminal ;;
    iTerm.app)      app=iTerm2 ;;
    vscode)         app=Code ;;
    ghostty)        app=Ghostty ;;
    WezTerm)        app=WezTerm ;;
  esac
  # Skip it while the terminal is the front app: you saw the command finish
  if [[ -n $app ]]; then
    front=$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
    [[ $front == *\"$app\"* ]] && return 0
  fi
  (( $2 )) && mark='✘'
  # Text is passed as arguments, never pasted into the script, so any command is safe
  osascript -e 'on run argv' \
            -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
            -e 'end run' \
            "${3[1,60]} finished after $(_prompt_duration $1) $mark" "${app:-Terminal}" \
            >/dev/null 2>&1 &!
}

_cmd_timer_start() {
  CMD_START_TIME=$SECONDS
  CMD_TEXT=$1
}

_prompt_precmd() {
  local -i last_status=$?   # first: the exit status of the command that just ran
  _prompt_status $last_status
  _prompt_git
  _prompt_dir
  PROMPT=$_prompt_full      # the transient prompt shortened it; restore it
  if [[ -n $CMD_START_TIME ]]; then
    local -i elapsed=$(( SECONDS - CMD_START_TIME ))
    (( elapsed >= 3 )) && print -P "%F{yellow}⏱️  $(_prompt_duration $elapsed)%f"
    if (( PROMPT_NOTIFY_SECONDS > 0 && elapsed >= PROMPT_NOTIFY_SECONDS )); then
      _prompt_notify $elapsed $last_status "$CMD_TEXT"
    fi
    unset CMD_START_TIME CMD_TEXT
  fi
  return 0
}

# Registered as hooks (not by defining precmd/preexec directly) so other tools'
# hooks can't silently replace them
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cmd_timer_start
add-zsh-hook precmd _prompt_precmd

# --- Extra context ------------------------------------------------------------------
typeset -g _prompt_extra_msg=""
_prompt_extra() {
  local extra=""
  # Active Python venv (% doubled so a % in the folder name isn't read as formatting)
  [[ -n $VIRTUAL_ENV ]]    && extra+=" %F{blue}(${${VIRTUAL_ENV:t}//\%/%%})%f"
  [[ -n $SSH_CONNECTION ]] && extra+=" %F{yellow}%n@%m%f"             # user@host, only over SSH
  (( ${#jobstates} ))      && extra+=" %F{yellow}⚙${#jobstates}%f"     # Background/suspended jobs
  [[ -w $PWD ]]            || extra+=" %F{red}🔒%f"                    # Folder you can't write to
  # A shell inside another shell (typing `zsh`, vim's :terminal): a reminder
  # that `exit` returns to the outer one. `reload` (exec zsh) keeps the level.
  (( SHLVL > 1 ))          && extra+=" %F{yellow}↳$SHLVL%f"
  _prompt_extra_msg=$extra
}
add-zsh-hook precmd _prompt_extra

setopt PROMPT_SUBST

_prompt_full='%F{cyan}${_prompt_dir_msg}%f${_prompt_git_msg}${_prompt_extra_msg} ${_prompt_status_msg}%(?.%F{green}.%F{red})❯%f '
PROMPT=$_prompt_full

# --- Transient prompt -------------------------------------------------------------------
# When you press Enter, the prompt you typed at is redrawn as just "❯ command",
# so scrollback shows your commands without repeated folders and branches.
# precmd puts the full prompt back before the next one is drawn.
_prompt_short='%(?.%F{green}.%F{red})❯%f '
_prompt_transient() {
  [[ $PROMPT == $_prompt_short ]] && return 0
  PROMPT=$_prompt_short
  zle .reset-prompt
}
zle -N zle-line-finish _prompt_transient

# ==============================================================================
# 4. ERROR HANDLERS & HOOKS
# ==============================================================================
command_not_found_handler() {
  # print -P only for the colors; the command name is printed raw (-r) so a
  # stray % in it isn't treated as prompt formatting
  print -Pn "%F{red}zsh: command not found: %F{yellow}" >&2
  print -rn -- "$1" >&2
  print -P "%f" >&2
  return 127
}

# ==============================================================================
# 5. KEYBINDINGS, FUNCTIONS & ALIASES
# ==============================================================================
bindkey -e

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# Up/Down search history for lines starting with what's typed. Arrows send
# ^[[A/^[[B normally and ^[OA/^[OB in "application" mode, so bind both.
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search

# ------------------------------------------------------------------------------
# Command-line syntax coloring, as you type (built in, no plugin needed)
# zsh calls zle-line-pre-redraw before each redraw; we fill region_highlight with
# color ranges. Ranges are 0-based, with the end position not included.
#   command word  green if it runs, red if not   (set first word after ; | && etc.)
#   'strings'     yellow      -options     cyan      $variables   magenta
#   # comments    grey        | & ; operators  bold
# ------------------------------------------------------------------------------
_highlight_line() {
  region_highlight=()
  local -i i=1 n=${#BUFFER} start expect_cmd=1 after_wrapper=0
  local ch word q target
  # Words that can start a command besides programs, aliases, functions, builtins
  local -a reserved=(if then else elif fi for while until do done case esac
                     function select in time coproc repeat '[[' '{' '}' '!')
  while (( i <= n )); do
    ch=$BUFFER[i]

    # A newline ends a command, just like ;
    if [[ $ch == $'\n' ]]; then
      expect_cmd=1; after_wrapper=0; (( i++ )); continue
    fi
    if [[ $ch == [[:space:]] ]]; then (( i++ )); continue; fi
    start=$i

    # Comment: # at the start of a word runs to the end of the line
    if [[ $ch == '#' ]]; then
      region_highlight+=("$((start-1)) $n fg=8")
      break
    fi

    # Quoted string: up to the matching quote (or end of line if unclosed).
    # Inside "double quotes" a backslash escapes the next character.
    if [[ $ch == [\'\"] ]]; then
      q=$ch; (( i++ ))
      while (( i <= n )) && [[ $BUFFER[i] != $q ]]; do
        [[ $q == '"' && $BUFFER[i] == '\' ]] && (( i++ ))
        (( i++ ))
      done
      (( i++ ))
      (( i > n + 1 )) && (( i = n + 1 ))
      region_highlight+=("$((start-1)) $((i-1)) fg=yellow")
      expect_cmd=0
      continue
    fi

    # Operators: ; | & and runs of them (||, &&, ;;)
    if [[ $ch == [\;\|\&] ]]; then
      while (( i <= n )) && [[ $BUFFER[i] == [\;\|\&] ]]; do (( i++ )); done
      region_highlight+=("$((start-1)) $((i-1)) bold")
      expect_cmd=1; after_wrapper=0
      continue
    fi

    # (( starts arithmetic; ( starts a subshell whose first word is a command
    if [[ $ch == '(' ]]; then
      if (( expect_cmd )) && [[ $BUFFER[i+1] == '(' ]]; then
        (( i += 2 ))
        region_highlight+=("$((start-1)) $((i-1)) fg=green")
        expect_cmd=0
      else
        (( i++ )); expect_cmd=1
      fi
      after_wrapper=0
      continue
    fi
    if [[ $ch == ')' ]]; then (( i++ )); expect_cmd=0; continue; fi

    # Bare word: runs until a space, quote, operator or parenthesis.
    # A backslash keeps the next character in the word (\" is not a quote).
    while (( i <= n )); do
      ch=$BUFFER[i]
      if [[ $ch == '\' ]]; then (( i += 2 )); continue; fi
      [[ $ch == [[:space:]\'\"\;\|\&\(\)] ]] && break
      (( i++ ))
    done
    (( i > n + 1 )) && (( i = n + 1 ))
    word=$BUFFER[start,i-1]

    if (( expect_cmd )) && [[ $word != [A-Za-z_]*=* ]]; then
      # An option to a wrapper (sudo -u root ls): the next word may be the
      # option's argument rather than a command, so stop checking here
      if (( after_wrapper )) && [[ $word == -* ]]; then
        region_highlight+=("$((start-1)) $((i-1)) fg=cyan")
        expect_cmd=0; after_wrapper=0
        continue
      fi
      case $word in
        # Wrappers run another command next, so the next word is still a command
        sudo|nohup|builtin|command|exec|noglob|nocorrect)
          region_highlight+=("$((start-1)) $((i-1)) fg=green")
          expect_cmd=1; after_wrapper=1
          ;;
        *)
          after_wrapper=0
          target=${word/#\~/$HOME}
          if (( ${+commands[$word]} || ${+aliases[$word]} || ${+functions[$word]} \
                || ${+builtins[$word]} || ${reserved[(Ie)$word]} )) \
             || [[ $word == */* && -x $target && ! -d $target ]] \
             || [[ -o autocd && -d $target ]]; then
            # A program, path to a program, keyword, or a folder (AUTO_CD cds)
            region_highlight+=("$((start-1)) $((i-1)) fg=green")
          else
            region_highlight+=("$((start-1)) $((i-1)) fg=red")
          fi
          # Keywords like if/then/do/{ are followed by a command; for/case/fi are not
          expect_cmd=0
          case $word in
            if|then|else|elif|do|while|until|time|'!'|'{') expect_cmd=1 ;;
          esac
          ;;
      esac
    elif [[ $word == -* ]]; then
      region_highlight+=("$((start-1)) $((i-1)) fg=cyan")
    elif [[ $word == *\$* ]]; then
      region_highlight+=("$((start-1)) $((i-1)) fg=magenta")
    fi
  done
}
zle -N zle-line-pre-redraw _highlight_line
# Also color a line that starts out filled in (Esc-q push-line, print -z), which
# otherwise stays plain until the first keystroke
zle -N zle-line-init _highlight_line

# Functions and aliases live in their own files next to this one in the dotfiles
# repo. ${(%):-%x} is this file's path; :A follows the ~/.zshrc symlink to the
# repo. Functions load first so aliases can't rewrite the commands inside them.
() {
  local dir=${${(%):-%x}:A:h} f
  for f in "$dir"/functions.zsh "$dir"/aliases.zsh; do
    if [[ -f "$f" ]]; then source "$f"; fi
  done
}

# ==============================================================================
# 6. FOLLOW MACOS LIGHT/DARK MODE (switches the Terminal.app profile)
# ==============================================================================
# Before each prompt (at most every 5s), check the macOS appearance. When it
# changes, switch every Terminal tab -- and the profile new windows open with --
# to the matching profile. The prompt colors follow because they use the
# profile's palette. Only active in macOS Terminal; other terminals are untouched.
# If macOS asks whether Terminal may control Terminal, allow it.
if [[ "$OSTYPE" == darwin* && "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  # Oceanic Next profiles from terminal/ (installed by install.sh). Until they're
  # installed, Apple's built-in Clear Dark / Clear Light are used instead.
  TERMINAL_DARK_PROFILE="Oceanic Next Dark"
  TERMINAL_LIGHT_PROFILE="Oceanic Next Light"
  typeset -g _appearance_checked_at=-999 _appearance_profile=""

  # Once a profile is found it's remembered, so Terminal's settings file is only
  # read again while a profile is still missing (to notice it being installed)
  typeset -gA _terminal_profiles_found
  _terminal_profile_installed() {
    (( ${+_terminal_profiles_found[$1]} )) && return 0
    /usr/libexec/PlistBuddy -c "Print ':Window Settings:$1:name'" \
      ~/Library/Preferences/com.apple.Terminal.plist >/dev/null 2>&1 || return 1
    _terminal_profiles_found[$1]=1
  }

  _sync_terminal_appearance() {
    (( SECONDS - _appearance_checked_at < 5 )) && return
    _appearance_checked_at=$SECONDS

    local profile=$TERMINAL_LIGHT_PROFILE fallback="Clear Light"
    if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]]; then
      profile=$TERMINAL_DARK_PROFILE fallback="Clear Dark"
    fi
    _terminal_profile_installed "$profile" || profile=$fallback

    # Compare the profile, not just the mode, so installing the Oceanic profiles
    # later is picked up without restarting the shell
    [[ $profile == $_appearance_profile ]] && return
    _appearance_profile=$profile

    # Run in the background (&!) so the prompt never waits on AppleScript
    osascript - "$profile" >/dev/null 2>&1 <<'APPLESCRIPT' &!
on run argv
  set profileName to item 1 of argv
  tell application "Terminal"
    set targetSettings to settings set profileName
    set default settings to targetSettings
    set startup settings to targetSettings
    repeat with w in windows
      repeat with t in tabs of w
        if name of current settings of t is not profileName then set current settings of t to targetSettings
      end repeat
    end repeat
  end tell
end run
APPLESCRIPT
  }

  add-zsh-hook precmd _sync_terminal_appearance

  # Also check while sitting idle at a prompt. zsh sends itself an ALRM signal
  # every TMOUT seconds of idle time; because TRAPALRM is defined, it runs this
  # instead of closing the shell. (Define TRAPALRM before setting TMOUT.)
  TRAPALRM() {
    _appearance_checked_at=-999   # skip the 5s throttle; the timer already paces it
    _sync_terminal_appearance
  }
  TMOUT=5
fi

# ==============================================================================
# 7. MACHINE-SPECIFIC SETTINGS (not in the dotfiles repo)
# ==============================================================================
# Put secrets, API keys and anything only for this computer in ~/.zshrc.local
if [[ -f ~/.zshrc.local ]]; then source ~/.zshrc.local; fi  # if/fi, not &&, so a missing file isn't a failure
