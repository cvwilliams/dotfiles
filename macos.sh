#!/usr/bin/env bash
# macos.sh -- macOS preferences applied with `defaults write`.
# Read it before running: ./macos.sh   (or ./macos.sh -y to skip the prompt)
#
# Part 1 is the core set of preferences. Part 2 has popular optional extras, all
# commented out: uncomment any you want and re-run. Safe to run more than once.
#
# Some changes only take effect after logging out (trackpad, keyboard repeat).
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

if [[ "${1:-}" != "-y" ]]; then
  read -r -p "Apply macOS preferences from $(basename "$0")? Finder and the Dock will restart. [y/N] " reply || reply=""
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Nothing changed."; exit 0; }
fi

# Close System Settings so it doesn't overwrite these changes when it quits
# (only if it's running; telling a closed app to quit can launch it first)
osascript -e 'if application "System Settings" is running then tell application "System Settings" to quit' 2>/dev/null || true

echo "Applying preferences..."

# ==============================================================================
# PART 1: CORE PREFERENCES
# ==============================================================================

# --- Keyboard & text ----------------------------------------------------------
defaults write -g NSAutomaticCapitalizationEnabled -bool true     # Capitalize words automatically
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool true # Double-space types a period

# --- Files & windows ----------------------------------------------------------
defaults write -g AppleShowAllExtensions -bool true               # Always show file extensions

# --- Finder -------------------------------------------------------------------
defaults write com.apple.finder ShowPathbar -bool true            # Path bar at the bottom
defaults write com.apple.finder ShowStatusBar -bool true          # Item count & free space
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # List view (icnv=icons, clmv=columns, glyv=gallery)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # Search the current folder, not the whole Mac
defaults write com.apple.finder NewWindowTarget -string "PfHm"    # New windows open your home folder
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Don't litter network and USB drives with .DS_Store files
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock ---------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true                 # Hide the Dock until you hover
defaults write com.apple.dock tilesize -int 39                    # Icon size in pixels
defaults write com.apple.dock show-recents -bool false            # No "recent apps" section
defaults write com.apple.dock minimize-to-application -bool true  # Minimize windows into their app icon
defaults write com.apple.dock mineffect -string "scale"           # Scale effect instead of genie

# --- Trackpad (built-in and Bluetooth) -----------------------------------------
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true                    # Tap to click
  defaults write "$domain" TrackpadThreeFingerDrag -bool true     # Three-finger drag
done
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1  # Tap to click on the login screen too

# ==============================================================================
# PART 2: OPTIONAL EXTRAS (uncomment to enable)
# ==============================================================================

# --- Keyboard: faster repeat, useful in vim -----------------------------------
# defaults write -g KeyRepeat -int 2                 # Repeat speed (default 6; lower is faster)
# defaults write -g InitialKeyRepeat -int 15         # Delay before repeat (default 25)
# defaults write -g ApplePressAndHoldEnabled -bool false  # Holding a key repeats it instead of showing accents

# --- Text: stop "smart" substitutions that break code -------------------------
# defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false  # Keep straight quotes
# defaults write -g NSAutomaticDashSubstitutionEnabled -bool false   # Keep -- as two hyphens
# defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false # No autocorrect

# --- Keyboard navigation ------------------------------------------------------
# defaults write -g AppleKeyboardUIMode -int 2       # Tab moves between all controls in dialogs

# --- Save & print dialogs -----------------------------------------------------
# defaults write -g NSNavPanelExpandedStateForSaveMode -bool true   # Save dialogs open expanded
# defaults write -g PMPrintingExpandedStateForPrint -bool true      # Print dialogs open expanded
# defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false   # Save to disk, not iCloud, by default

# --- Finder -------------------------------------------------------------------
# defaults write com.apple.finder AppleShowAllFiles -bool true      # Show hidden files (or press Cmd-Shift-.)
# defaults write com.apple.finder _FXSortFoldersFirst -bool true    # Folders above files when sorting by name
# defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false  # No warning when renaming extensions
# chflags nohidden ~/Library                                        # Show ~/Library in Finder

# --- Dock ---------------------------------------------------------------------
# defaults write com.apple.dock autohide-delay -float 0             # Dock appears instantly on hover
# defaults write com.apple.dock autohide-time-modifier -float 0.3   # Faster show/hide animation
# defaults write com.apple.dock mru-spaces -bool false              # Don't reorder Spaces by recent use

# --- Screenshots --------------------------------------------------------------
# mkdir -p "$HOME/Pictures/Screenshots"
# defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"  # Not the Desktop
# defaults write com.apple.screencapture type -string "png"         # png, jpg, pdf, heic
# defaults write com.apple.screencapture disable-shadow -bool true  # No drop shadow on window screenshots

# --- TextEdit -----------------------------------------------------------------
# defaults write com.apple.TextEdit RichText -int 0                 # New documents are plain text

# ==============================================================================
# Restart affected apps so changes show up now
# ==============================================================================
for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "Done. Log out and back in for keyboard and trackpad changes to fully apply."
