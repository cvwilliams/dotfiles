# zprofile -- environment for login shells (PATH, editor, pager)
# zsh reads this once per login session, before zshrc. Exported variables are
# inherited by everything started afterwards, so they only need setting here.
# Interactive behavior (prompt, aliases, completion) lives in zshrc.

# ==============================================================================
# 1. PATH
# ==============================================================================
typeset -U path PATH          # Drop duplicate PATH entries automatically

# Homebrew, if installed (Apple Silicon, then Intel)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

path=("$HOME/bin" $path)      # Personal scripts come first

# ==============================================================================
# 2. EDITOR, PAGER & LOCALE
# ==============================================================================
export EDITOR=vim             # Used by git, crontab, etc.
export VISUAL=vim
export PAGER=less
export LESS='-iRFX'           # Smart-case search, keep colors, quit if one screen, don't clear
export MANPAGER='vim +MANPAGER --not-a-term -'  # Read man pages in vim
export CLICOLOR=1             # Colored ls output
export LANG=en_US.UTF-8

# ==============================================================================
# 3. MACHINE-SPECIFIC SETTINGS (not in the dotfiles repo)
# ==============================================================================
# Tool integrations and anything only for this computer go in ~/.zprofile.local
if [[ -f ~/.zprofile.local ]]; then source ~/.zprofile.local; fi
