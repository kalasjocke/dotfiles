#!/bin/bash
# Apply the macOS settings that differ from a fresh install. Safe to run again.
# Key repeat and trackpad changes take effect after logging out and in.

set -euo pipefail

# Appearance
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Keyboard: fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Trackpad: tap to click and tracking speed
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.5

# Dock: hide it, 64 px icons, no magnification
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 64
defaults write com.apple.dock magnification -bool false

# Hot corners: 2 is Mission Control, 3 is application windows, 4 is desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 3
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 2
defaults write com.apple.dock wvous-br-modifier -int 0

# Finder: list view, new windows open Recents
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder NewWindowTarget -string PfAF

# Screenshots: capture a window, save to a file, show clicks in recordings
defaults write com.apple.screencapture style -string window
defaults write com.apple.screencapture target -string file
defaults write com.apple.screencapture showsClicks -bool true

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Applied macOS settings. Log out and in for key repeat and trackpad changes."
