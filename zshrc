# zshrc -- minimal, plugin-free zsh config for macOS
# Sections: 1 History & options, 2 Completion, 3 Prompt, 4 Error handlers,
# 5 Keybindings & aliases, 6 Light/dark Terminal profile, 7 Local overrides.

# ==============================================================================
# 1. ENVIRONMENT & PERFORMANCE TUNING
# ==============================================================================
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

setopt SHARE_HISTORY          # Share history across sessions
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates when file is full
setopt HIST_IGNORE_DUPS       # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove old duplicates on new entries
setopt HIST_FIND_NO_DUPS      # Filter duplicates in history search
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicates to file
setopt HIST_REDUCE_BLANKS     # Trim blank spaces

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
autoload -U compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- No matches found --%f'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# ==============================================================================
# 3. MINIMALIST SINGLE-LINE PROMPT & TIMER
# ==============================================================================
autoload -Uz vcs_info
autoload -U colors && colors

zstyle ':vcs_info:git:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '%F{red}*%f'
zstyle ':vcs_info:git:*' stagedstr '%F{green}+%f'
zstyle ':vcs_info:git:*' formats ' %F{magenta}🌿 %b%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}🌿 %b|%a%u%c%f'

preexec() {
  CMD_START_TIME=$SECONDS
}

precmd() {
  vcs_info
  if [[ -n $CMD_START_TIME ]]; then
    local elapsed=$(( SECONDS - CMD_START_TIME ))
    if (( elapsed >= 3 )); then
      print -P "%F{yellow}⏱️  ${elapsed}s%f"
    fi
    unset CMD_START_TIME
  fi
}

setopt PROMPT_SUBST

# Clean single-line layout: ~ (git) ❯
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} %F{green}❯%f '
PROMPT_FAILURE='%F{red}❯%f '
PROMPT="%(?.${PROMPT}.${PROMPT/❯/${PROMPT_FAILURE}})"

# ==============================================================================
# 4. ERROR HANDLERS & HOOKS
# ==============================================================================
command_not_found_handler() {
  print -P "%F{red}zsh: command not found: %F{yellow}$1%f" >&2
  return 127
}

# ==============================================================================
# 5. KEYBINDINGS & ALIASES
# ==============================================================================
bindkey -e

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls="ls -G"
  alias ll="ls -lhG"
  alias la="ls -lahG"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
fi

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias grep="grep --color=auto"
alias reload="exec zsh"

# ==============================================================================
# 6. FOLLOW MACOS LIGHT/DARK MODE (switches the Terminal.app profile)
# ==============================================================================
# Before each prompt (at most every 5s), check the macOS appearance. When it
# changes, switch every Terminal tab -- and the profile new windows open with --
# to the matching profile. The prompt colors follow because they use the
# profile's palette. Only active in macOS Terminal; other terminals are untouched.
# If macOS asks whether Terminal may control Terminal, allow it.
if [[ "$OSTYPE" == darwin* && "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  TERMINAL_DARK_PROFILE="Clear Dark"
  TERMINAL_LIGHT_PROFILE="Clear Light"
  typeset -g _appearance_checked_at=-999 _appearance_mode=""

  _sync_terminal_appearance() {
    (( SECONDS - _appearance_checked_at < 5 )) && return
    _appearance_checked_at=$SECONDS

    local mode=light
    [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]] && mode=dark
    [[ $mode == $_appearance_mode ]] && return
    _appearance_mode=$mode

    local profile=$TERMINAL_LIGHT_PROFILE
    [[ $mode == dark ]] && profile=$TERMINAL_DARK_PROFILE

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

  autoload -Uz add-zsh-hook
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
