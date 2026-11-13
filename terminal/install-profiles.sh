#!/usr/bin/env bash
# Import the Oceanic Next profiles into Terminal.app. Profiles that are already
# installed are skipped, so this is safe to re-run.
#
# Terminal imports a profile by opening it, which also opens one window per new
# profile; close those windows afterwards. To pick up color changes, delete the
# profile in Terminal > Settings > Profiles and run this again.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFS="$HOME/Library/Preferences/com.apple.Terminal.plist"

profile_installed() {
  /usr/libexec/PlistBuddy -c "Print ':Window Settings:$1:name'" "$PREFS" >/dev/null 2>&1
}

for file in "$DIR"/*.terminal; do
  name="$(basename "$file" .terminal)"
  if profile_installed "$name"; then
    echo "ok      Terminal profile: $name"
  else
    open -a Terminal "$file"
    echo "import  Terminal profile: $name (close the window it opened)"
  fi
done
