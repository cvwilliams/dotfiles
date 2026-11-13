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
autoload -Uz vcs_info
autoload -U colors && colors

zstyle ':vcs_info:git:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '%F{red}*%f'
zstyle ':vcs_info:git:*' stagedstr '%F{green}+%f'
zstyle ':vcs_info:git:*' formats ' %F{magenta}🌿 %b%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}🌿 %b|%a%u%c%f'

_cmd_timer_start() {
  CMD_START_TIME=$SECONDS
}

_prompt_precmd() {
  vcs_info
  if [[ -n $CMD_START_TIME ]]; then
    local elapsed=$(( SECONDS - CMD_START_TIME ))
    if (( elapsed >= 3 )); then
      print -P "%F{yellow}⏱️  ${elapsed}s%f"
    fi
    unset CMD_START_TIME
  fi
}

# Registered as hooks (not by defining precmd/preexec directly) so other tools'
# hooks can't silently replace them
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cmd_timer_start
add-zsh-hook precmd _prompt_precmd

setopt PROMPT_SUBST

# Clean single-line layout: ~ (git) ❯   -- the ❯ turns red after a failed command
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} %(?.%F{green}.%F{red})❯%f '

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

  _terminal_profile_installed() {
    /usr/libexec/PlistBuddy -c "Print ':Window Settings:$1:name'" \
      ~/Library/Preferences/com.apple.Terminal.plist >/dev/null 2>&1
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
