# aliases.zsh -- shell aliases, loaded by zshrc
# Personal or machine-specific aliases go in ~/.zshrc.local instead.

# ==============================================================================
# NAVIGATION
# ==============================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias dotfiles="cd ~/Projects/dotfiles"

# ==============================================================================
# LISTING & FILES
# ==============================================================================
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -G"
  alias ll="ls -lhG"
  alias la="ls -lahG"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
fi

# Ask before overwriting or deleting
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias mkdir="mkdir -p"          # Create parent folders as needed
alias df="df -h"                # Human-readable sizes
alias du="du -h"
alias grep="grep --color=auto"

# ==============================================================================
# EDITING & SHELL
# ==============================================================================
alias v="vim"
alias zshrc="vim ~/.zshrc"
alias vimrc="vim ~/.vimrc"
alias reload="exec zsh"         # Restart the shell to pick up config changes
alias path='print -l $path'     # PATH, one entry per line

# ==============================================================================
# MACOS
# ==============================================================================
alias o="open ."                                # This folder in Finder
alias cpwd='print -rn -- "$PWD" | pbcopy'       # Copy the current path
alias awake="caffeinate -dims"                  # Keep the Mac awake until Ctrl-C
alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidehidden="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# ==============================================================================
# GLOBAL ALIASES (zsh only: expand anywhere in a command, not just at the start)
# ==============================================================================
alias -g G="| grep -i"          # history G docker
alias -g L="| less"             # git log L
alias -g C="| pbcopy"           # cat notes.txt C
alias -g N=">/dev/null 2>&1"    # noisy-command N
