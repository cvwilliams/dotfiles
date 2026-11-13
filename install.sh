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

link vimrc .vimrc
link zprofile .zprofile
link zshrc .zshrc

echo
echo "Done. Open a new terminal tab (or run: exec zsh) to load the new shell config."
echo "macOS preferences are separate: review macos.sh, then run it yourself."
