# dotfiles

[![CI](https://github.com/cvwilliams/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/cvwilliams/dotfiles/actions/workflows/ci.yml)

A small, dependency-free setup for zsh, Vim and git on macOS. No plugin managers, no
frameworks: everything is plain config files using what ships with macOS.

## Features

**Vim** (`vimrc`)
- Neovim's sensible defaults ported to Vim: mouse support, search match counts,
  popup command-line completion, faster `<Esc>`, mode-aware cursor shapes
- Neovim's default mappings: `Y`, `&`, visual `*`/`#`, undoable `Ctrl-U`/`Ctrl-W`,
  and `[q` `]q` `[b` `]b` `[l` `]l` `[a` `]a` bracket navigation
- Built-in packages enabled: `gc` commenting, `%` matching (matchit),
  EditorConfig support and `:Man`
- A colorscheme built on the [Oceanic Next](https://github.com/voronianski/oceanic-next-color-scheme)
  palette, with a matching light variant, that **follows the macOS light/dark
  setting automatically**, even while Vim is open
- Persistent undo, no swap files, space as the leader key

**zsh** (`zshrc`)
- Large deduplicated history shared across sessions
- Built-in completion with case-insensitive and fuzzy matching
- Minimal one-line prompt with the current directory, git branch and status,
  turning red after a failed command
- Run time shown for commands that take 3 seconds or more
- In macOS Terminal, **switches the Terminal profile to match light/dark mode**
- Loads `~/.zshrc.local` for machine-specific settings and secrets

**Functions** (`functions.zsh`)

| Command | What it does |
|---|---|
| `mkcd <dir>` | Create a folder (and parents) and `cd` into it |
| `up [n]` | Go up `n` folders: `up 3` = `cd ../../..` |
| `cdf` | `cd` to the folder open in the front Finder window |
| `ff <text>` | Find files by name, case-insensitive, skipping `.git` |
| `bak <file>` | Timestamped copy: `notes.txt.bak-20260101-120000` |
| `extract <archive>` | Unpack tar, gz, bz2, xz, zip or 7z |
| `ql <file>` | Quick Look preview from the terminal |
| `gclone <url>` | `git clone`, then `cd` into it |
| `serve [port]` | Share this folder at `http://localhost:8000` (this Mac only) |
| `port <n>` | What's listening on a TCP port |
| `localip` | This Mac's address on the local network |

**Aliases** (`aliases.zsh`)
- Navigation: `..`, `...`, `....`, `dotfiles`
- Files: colored `ls`/`ll`/`la`, `mkdir -p`, human-readable `df`/`du`, and
  `cp`/`mv`/`rm` that ask before overwriting or deleting
- Shell: `v` (vim), `zshrc`, `vimrc`, `reload`, `path` (one entry per line)
- macOS: `o` (open in Finder), `cpwd` (copy path), `awake`, `flushdns`,
  `showhidden`/`hidehidden`
- zsh global aliases that work anywhere in a command: `G` (`| grep -i`),
  `L` (`| less`), `C` (`| pbcopy`), `N` (silence output). For example,
  `history G docker` or `cat notes.txt C`

**Login environment** (`zprofile`)
- `PATH` with `~/bin` first, duplicates removed, and Homebrew set up if installed
- Vim as `EDITOR`/`VISUAL`, and as the man page viewer (`MANPAGER`)
- Friendlier `less` defaults: smart-case search, colors, exits on short output
- Loads `~/.zprofile.local` for machine-specific tool integrations

**git** (`gitconfig`, `gitignore_global`)
- `main` as the default branch, vim as the editor
- Safer defaults: fast-forward-only pulls, auto-pruned remote branches, first
  push of a new branch sets up tracking automatically
- Easier-to-read diffs and conflicts: histogram diffs, moved lines highlighted,
  `zdiff3` conflict markers, remembered conflict resolutions (`rerere`)
- Aliases: `git st`, `git lg` (graph log), `git last`, `git undo` (undo last
  commit, keep changes), `git amend`, `git unstage`, `git discard`,
  `git branches`, `git aliases`
- A global ignore list for macOS clutter, Vim swap files and `.env` files
- Your name and email stay in `~/.gitconfig.local`, outside the repo

**macOS** (`macos.sh`)
- Finder, Dock and trackpad preferences applied with `defaults write`
- A commented-out list of popular extras (faster key repeat, no smart quotes,
  screenshot folder and more) to enable as you like

## Requirements

- macOS with zsh (the default shell)
- Vim 9.1 or later (the version bundled with current macOS)

## Install

```bash
git clone https://github.com/cvwilliams/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` symlinks `gitconfig`, `gitignore_global`, `vimrc`, `zprofile` and
`zshrc` into your home folder as dotfiles (`~/.gitconfig` and so on). Anything
already there is renamed to `<name>.backup-<timestamp>`, never deleted. It is
safe to run again.

On first install, the name and email from your existing `~/.gitconfig` are
moved into `~/.gitconfig.local`. On a new machine, set them there:

```bash
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

Because the files are symlinked, editing `~/.zshrc` and the others edits the
copy in the repo, ready to commit. Installers that append lines to these files
(many do) also edit the repo, so check `git diff` and move machine-specific
lines into the `.local` files.

### macOS preferences

`macos.sh` changes system preferences, so read through it before running it.
It asks for confirmation (skip that with `-y`) and restarts Finder and the Dock:

```bash
~/Projects/dotfiles/macos.sh
```

Keyboard and trackpad changes may need a log out to take effect.

## Customizing

| To change | Edit |
|---|---|
| Vim colors | The `s:palettes` dictionary in section 5 of `vimrc` |
| Terminal profiles used for light/dark | `TERMINAL_DARK_PROFILE` and `TERMINAL_LIGHT_PROFILE` in `zshrc` (default: Clear Dark / Clear Light) |
| Aliases and functions | `aliases.zsh` and `functions.zsh`, loaded automatically by `zshrc` |
| macOS preferences | Uncomment lines in part 2 of `macos.sh` |
| Git identity, signing keys, work-only settings | `~/.gitconfig.local`, which is not tracked |
| Anything else for one machine only | Create `~/.zprofile.local` (environment, tool setup) or `~/.zshrc.local` (aliases, secrets). Neither is tracked. |

## Uninstall

Remove the symlinks and restore a backup if you have one:

```bash
rm ~/.gitconfig ~/.gitignore_global ~/.vimrc ~/.zprofile ~/.zshrc
mv ~/.gitconfig.backup-<timestamp> ~/.gitconfig   # if a backup exists
mv ~/.vimrc.backup-<timestamp> ~/.vimrc
mv ~/.zprofile.backup-<timestamp> ~/.zprofile
mv ~/.zshrc.backup-<timestamp> ~/.zshrc
```

## Testing

```bash
tests/smoke.sh
```

The smoke tests install everything into a throwaway home folder (your real one
is untouched), then check that zsh starts with no output and a clean exit
status, Vim starts with no errors, and `macos.sh` changes nothing without
confirmation.

GitHub Actions runs these tests on macOS for every push and pull request, along
with [ShellCheck](https://www.shellcheck.net) on the shell scripts and a full
run of `macos.sh` on the throwaway runner.

## Credits

The color palette is from [Oceanic Next](https://github.com/voronianski/oceanic-next-color-scheme)
by Dmitri Voronianski. The Vim colorscheme here is an independent implementation
of that palette, not a copy of an existing theme.

## License

[MIT](LICENSE). Copy anything you find useful.
