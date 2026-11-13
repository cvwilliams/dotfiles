# functions.zsh -- shell functions, loaded by zshrc
# Personal or machine-specific functions go in ~/.zshrc.local instead.

# ==============================================================================
# NAVIGATION
# ==============================================================================

# mkcd <dir> -- create a folder (and parents) and cd into it
mkcd() {
  [[ -n "$1" ]] || { echo "usage: mkcd <dir>" >&2; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}

# up [n] -- go up n folders (default 1): up 3 = cd ../../..
up() {
  local n=${1:-1}
  [[ "$n" == <-> && "$n" -gt 0 ]] || { echo "usage: up [number]" >&2; return 1; }
  cd "$(printf '../%.0s' {1..$n})"
}

# cdf -- cd to the folder open in the frontmost Finder window
# (macOS may ask once to let your terminal control Finder)
cdf() {
  local dir
  dir="$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then POSIX path of (target of front Finder window as alias)' 2>/dev/null)"
  [[ -n "$dir" ]] || { echo "cdf: no Finder window open" >&2; return 1; }
  cd -- "$dir"
}

# ==============================================================================
# FILES
# ==============================================================================

# ff <text> -- find files whose name contains <text> (case-insensitive), skipping .git
ff() {
  [[ -n "$1" ]] || { echo "usage: ff <part of a file name>" >&2; return 1; }
  find . -iname "*$1*" -not -path '*/.git/*' 2>/dev/null
}

# bak <file> -- make a timestamped copy next to the original
bak() {
  [[ -e "$1" ]] || { echo "usage: bak <file or folder>" >&2; return 1; }
  local copy="${1%/}.bak-$(date +%Y%m%d-%H%M%S)"
  command cp -R -- "${1%/}" "$copy" && echo "$copy"
}

# extract <archive> -- unpack any common archive format
extract() {
  [[ -f "$1" ]] || { echo "usage: extract <archive>" >&2; return 1; }
  case "${1:l}" in
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz|*.tbz2|*.tar.xz|*.txz|*.tar.zst)
                tar -xf "$1" ;;
    *.zip)      unzip -q "$1" ;;
    *.gz)       gunzip -k "$1" ;;
    *.bz2)      bunzip2 -k "$1" ;;
    *.xz)       unxz -k "$1" ;;
    *.7z)       command -v 7z >/dev/null || { echo "extract: 7z isn't installed" >&2; return 1; }
                7z x "$1" ;;
    *)          echo "extract: don't know how to unpack '$1'" >&2; return 1 ;;
  esac
}

# ql <file...> -- preview files with Quick Look (Esc or Space to close)
ql() {
  [[ $# -gt 0 ]] || { echo "usage: ql <file>..." >&2; return 1; }
  qlmanage -p "$@" >/dev/null 2>&1
}

# ==============================================================================
# DEVELOPMENT
# ==============================================================================

# gclone <url> [dir] -- git clone, then cd into the new folder
gclone() {
  [[ -n "$1" ]] || { echo "usage: gclone <url> [dir]" >&2; return 1; }
  local dir="${2:-${${1%/}:t}}"
  dir="${dir%.git}"
  git clone -- "$1" "$dir" && cd -- "$dir"
}

# serve [port] -- share the current folder at http://localhost:<port> (default 8000)
# Bound to 127.0.0.1, so only this Mac can reach it
serve() {
  local port=${1:-8000}
  echo "Serving $PWD at http://localhost:$port  (Ctrl-C to stop)"
  python3 -m http.server "$port" --bind 127.0.0.1
}

# port <number> -- show what's listening on a TCP port
port() {
  [[ "$1" == <-> ]] || { echo "usage: port <number>" >&2; return 1; }
  lsof -nP -iTCP:"$1" -sTCP:LISTEN || echo "Nothing is listening on port $1"
}

# localip -- this Mac's IP address on the local network (Wi-Fi or Ethernet)
localip() {
  local iface ip
  for iface in en0 en1 en2; do
    ip="$(ipconfig getifaddr "$iface" 2>/dev/null)" && { echo "$ip"; return; }
  done
  echo "localip: not connected to a network" >&2
  return 1
}
