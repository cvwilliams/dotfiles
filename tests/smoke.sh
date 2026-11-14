#!/usr/bin/env bash
# Smoke tests: install the dotfiles into a throwaway home folder, then check
# that zsh and Vim start without errors. Your real home folder is not touched.
# Run locally with: tests/smoke.sh   (CI runs the same script on macOS)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
export TERM="${TERM:-xterm-256color}"
# Don't let the test installs import Terminal profiles (that opens real
# Terminal windows) when the tests themselves are run from Terminal.app
unset TERM_PROGRAM

pass() { echo "ok    $*"; }
fail() { echo "FAIL  $*" >&2; exit 1; }

# --- Syntax -------------------------------------------------------------------
zsh -n "$REPO/zshrc" || fail "zshrc has a syntax error"
zsh -n "$REPO/zprofile" || fail "zprofile has a syntax error"
zsh -n "$REPO/aliases.zsh" || fail "aliases.zsh has a syntax error"
zsh -n "$REPO/functions.zsh" || fail "functions.zsh has a syntax error"
bash -n "$REPO/install.sh" || fail "install.sh has a syntax error"
bash -n "$REPO/macos.sh" || fail "macos.sh has a syntax error"
bash -n "$REPO/bootstrap.sh" || fail "bootstrap.sh has a syntax error"
bash -n "$REPO/terminal/install-profiles.sh" || fail "terminal/install-profiles.sh has a syntax error"
for profile in "$REPO"/terminal/*.terminal; do
  plutil -lint -s "$profile" || fail "$(basename "$profile") is not a valid profile"
  for key in name BackgroundColor TextColor Font ANSIRedColor ANSIBrightWhiteColor; do
    plutil -extract "$key" raw -o /dev/null "$profile" 2>/dev/null \
      || plutil -extract "$key" xml1 -o /dev/null "$profile" \
      || fail "$(basename "$profile") is missing $key"
  done
done
pass "syntax"

# --- install.sh ---------------------------------------------------------------
# Start with an existing ~/.gitconfig, as on a Mac that already uses git
printf '[user]\n\tname = Test Person\n\temail = test@example.com\n' > "$TEST_HOME/.gitconfig"

HOME="$TEST_HOME" "$REPO/install.sh" >/dev/null
for f in .gitconfig .gitignore_global .vimrc .zprofile .zshrc; do
  [[ -L "$TEST_HOME/$f" ]] || fail "install.sh did not link ~/$f"
done
if HOME="$TEST_HOME" "$REPO/install.sh" | grep -qE '^(backup|moved)'; then
  fail "re-running install.sh changed files it had already set up"
fi
pass "install.sh links files and is safe to re-run"

# --- git ----------------------------------------------------------------------
[[ "$(HOME="$TEST_HOME" git config user.name)" == "Test Person" ]] \
  || fail "git name wasn't carried over to ~/.gitconfig.local"
[[ "$(HOME="$TEST_HOME" git config init.defaultBranch)" == "main" ]] \
  || fail "gitconfig settings aren't active"
HOME="$TEST_HOME" git config alias.st >/dev/null || fail "git aliases missing"
pass "git keeps your identity and loads gitconfig"

# --- zsh ----------------------------------------------------------------------
# A login + interactive shell must print nothing and start with exit status 0
# (a non-zero status turns the first prompt red).
out="$(HOME="$TEST_HOME" ZDOTDIR="$TEST_HOME" zsh -l -i -c 'print -r -- "status=$?"' </dev/null 2>&1)"
[[ "$out" == "status=0" ]] || fail "zsh startup printed or failed:
$out"
pass "zsh starts cleanly"

# aliases.zsh and functions.zsh are found through the ~/.zshrc symlink
# (Global aliases like G expand anywhere on a command line, so check them via
# the $galiases table rather than by name.)
out="$(HOME="$TEST_HOME" ZDOTDIR="$TEST_HOME" zsh -l -i -c 'whence -w mkcd extract reload; print "global G: ${+galiases[G]}"' </dev/null 2>&1)"
[[ "$out" == *"mkcd: function"* && "$out" == *"extract: function"* && "$out" == *"reload: alias"* && "$out" == *"global G: 1"* ]] \
  || fail "functions or aliases didn't load:
$out"
pass "functions and aliases load"

# --- Vim ----------------------------------------------------------------------
# Vim needs a terminal to load plugins normally, so run it under script(1)
# and record any error messages to a file.
cat > "$TEST_HOME/check.vim" <<EOF
redir! > $TEST_HOME/vim.out
silent messages
echo 'errmsg=' . v:errmsg
redir END
qa!
EOF
HOME="$TEST_HOME" script -q /dev/null vim -X -S "$TEST_HOME/check.vim" </dev/null >/dev/null 2>&1 || true
[[ -f "$TEST_HOME/vim.out" ]] || fail "Vim did not run the check script"
if grep -qE '^E[0-9]+:' "$TEST_HOME/vim.out" || ! grep -q '^errmsg=$' "$TEST_HOME/vim.out"; then
  fail "Vim reported errors:
$(cat "$TEST_HOME/vim.out")"
fi
pass "vim starts cleanly"

# --- macos.sh -----------------------------------------------------------------
"$REPO/macos.sh" </dev/null | grep -q 'Nothing changed' || fail "macos.sh changed things without confirmation"
pass "macos.sh asks before changing anything"

# --- bootstrap.sh -------------------------------------------------------------
# Clone this repo (its committed state) into a second throwaway home, as on a
# new Mac, then run it again to check that updating an existing clone works.
BOOT_HOME="$TEST_HOME/boot"
mkdir -p "$BOOT_HOME"
for run in first second; do
  HOME="$BOOT_HOME" DOTFILES_REPO="$REPO" DOTFILES_SKIP_MACOS=1 \
    bash "$REPO/bootstrap.sh" </dev/null >"$TEST_HOME/boot-$run.log" 2>&1 \
    || fail "bootstrap.sh ($run run) failed:
$(cat "$TEST_HOME/boot-$run.log")"
done
[[ "$(readlink "$BOOT_HOME/.zshrc")" == "$BOOT_HOME/Projects/dotfiles/zshrc" ]] \
  || fail "bootstrap.sh didn't clone to ~/Projects/dotfiles and link from there"
pass "bootstrap.sh clones, links and can re-run"

echo "All smoke tests passed."
