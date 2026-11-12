#!/bin/bash
# macOS preferences for both Macs. Wallpaper, Control Center icons and the Dock's
# app list are set by hand.
set -euo pipefail

defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Finder: path and status bars, list view, search the current folder, new windows at home
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder FXDefaultSearchScope -string SCev
defaults write com.apple.finder NewWindowTarget -string PfHm

# Trackpad, built-in and Magic Trackpad: tap to click, three-finger drag, right click
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true
  defaults write "$domain" TrackpadThreeFingerDrag -bool true
  defaults write "$domain" TrackpadRightClick -bool true
done
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Dock: keep Spaces in order; hot corners bottom-left app windows, bottom-right Quick Note
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock wvous-bl-corner -int 3
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 14

# Menu bar clock: weekday, seconds, AM/PM
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowSeconds -bool true
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0

killall Dock Finder ControlCenter 2>/dev/null || true
