# dotfiles

[![CI](https://github.com/cvwilliams/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/cvwilliams/dotfiles/actions/workflows/ci.yml)

A small, dependency-free setup for zsh and Vim on macOS. No plugin managers, no
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

**Login environment** (`zprofile`)
- `PATH` with `~/bin` first, duplicates removed, and Homebrew set up if installed
- Vim as `EDITOR`/`VISUAL`, and as the man page viewer (`MANPAGER`)
- Friendlier `less` defaults: smart-case search, colors, exits on short output
- Loads `~/.zprofile.local` for machine-specific tool integrations

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

`install.sh` symlinks `vimrc`, `zprofile` and `zshrc` into your home folder as
`~/.vimrc`, `~/.zprofile` and `~/.zshrc`. Anything already there is renamed to
`<name>.backup-<timestamp>`, never deleted. It is safe to run again.

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
| macOS preferences | Uncomment lines in part 2 of `macos.sh` |
| Anything for one machine only | Create `~/.zprofile.local` (environment, tool setup) or `~/.zshrc.local` (aliases, secrets). Neither is tracked. |

## Uninstall

Remove the symlinks and restore a backup if you have one:

```bash
rm ~/.vimrc ~/.zprofile ~/.zshrc
mv ~/.vimrc.backup-<timestamp> ~/.vimrc   # if a backup exists
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
