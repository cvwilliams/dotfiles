#!/usr/bin/env bash
# Link the dotfiles in this repo into your home folder.
# Safe to re-run: files already linked are left alone, and anything else in
# the way is renamed to <name>.backup-<timestamp> rather than deleted.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# link <file in repo> <path relative to $HOME>
link() {
  local src="$DOTFILES/$1" dest="$HOME/$2"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok      ~/$2"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mv "$dest" "$dest.backup-$STAMP"
    echo "backup  ~/$2 -> ~/$2.backup-$STAMP"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "linked  ~/$2 -> $src"
}

# Git identity lives in ~/.gitconfig.local, not the repo. On first install,
# carry over the name and email from an existing ~/.gitconfig before it's
# replaced by the link.
setup_git_identity() {
  local local_cfg="$HOME/.gitconfig.local" key value
  [[ -e "$local_cfg" ]] && return

  if [[ -f "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]]; then
    for key in user.name user.email; do
      if value="$(git config --file "$HOME/.gitconfig" --get "$key")"; then
        git config --file "$local_cfg" "$key" "$value"
      fi
    done
  fi

  if [[ -e "$local_cfg" ]]; then
    echo "moved   git name/email -> ~/.gitconfig.local"
  else
    echo "note    set your git identity in ~/.gitconfig.local:"
    echo "          git config --file ~/.gitconfig.local user.name \"Your Name\""
    echo "          git config --file ~/.gitconfig.local user.email \"you@example.com\""
  fi
}

setup_git_identity
link gitconfig .gitconfig
link gitignore_global .gitignore_global
link vimrc .vimrc
link zprofile .zprofile
link zshrc .zshrc

# Terminal.app color profiles (only when run from Terminal itself, since
# importing opens Terminal windows)
if [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
  "$DOTFILES/terminal/install-profiles.sh"
else
  echo "skip    Terminal profiles (run terminal/install-profiles.sh from Terminal.app)"
fi

echo
echo "Done. Open a new terminal tab (or run: exec zsh) to load the new shell config."
echo "macOS preferences are separate: review macos.sh, then run it yourself."
