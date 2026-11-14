#!/usr/bin/env bash
# bootstrap.sh -- set up a new Mac with these dotfiles in one command:
#
#   curl -fsSL https://raw.githubusercontent.com/cvwilliams/dotfiles/main/bootstrap.sh | bash
#
# 1. Installs Apple's Command Line Tools if missing (they provide git)
# 2. Clones the repo to ~/Projects/dotfiles, or updates an existing clone
# 3. Runs install.sh to link the dotfiles
# 4. Offers to run macos.sh to apply macOS preferences
#
# Nothing else is downloaded or installed.
#
# Options (environment variables):
#   DOTFILES_DIR=path       where to clone (default: ~/Projects/dotfiles)
#   DOTFILES_REPO=url       repo to clone (default: this GitHub repo)
#   DOTFILES_SKIP_MACOS=1   don't offer to run macos.sh

# Everything is inside main(), which runs on the last line, so a partial
# download from curl can't run half a script.
main() {
  set -euo pipefail

  local dir="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"
  local repo="${DOTFILES_REPO:-https://github.com/cvwilliams/dotfiles.git}"

  say() { printf '\n==> %s\n' "$*"; }

  if [[ "$(uname)" != "Darwin" ]]; then
    echo "These dotfiles are for macOS." >&2
    exit 1
  fi

  # --- Command Line Tools (git) ---------------------------------------------
  if ! xcode-select -p >/dev/null 2>&1; then
    say "Installing Apple's Command Line Tools (needed for git)"
    echo "A macOS dialog will appear. Click Install and wait for it to finish."
    xcode-select --install >/dev/null 2>&1 || true
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
    echo "Command Line Tools installed."
  fi

  # --- Clone or update ------------------------------------------------------
  if [[ -d "$dir/.git" ]]; then
    say "Updating $dir"
    git -C "$dir" pull --ff-only
  elif [[ -e "$dir" ]]; then
    echo "$dir already exists and isn't a git repo. Move it or set DOTFILES_DIR." >&2
    exit 1
  else
    say "Cloning dotfiles to $dir"
    mkdir -p "$(dirname "$dir")"
    git clone "$repo" "$dir"
  fi

  # --- Link -----------------------------------------------------------------
  say "Linking dotfiles"
  "$dir/install.sh"

  # --- macOS preferences ----------------------------------------------------
  # When piped from curl, stdin is the script itself, so questions go through
  # the terminal (/dev/tty) instead
  if [[ -z "${DOTFILES_SKIP_MACOS:-}" ]] && { : </dev/tty; } 2>/dev/null; then
    say "macOS preferences"
    "$dir/macos.sh" </dev/tty
  fi

  say "All set. Open a new terminal window to start using everything."
}

main "$@"
