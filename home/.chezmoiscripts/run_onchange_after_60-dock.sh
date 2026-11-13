#!/bin/bash
# Dock apps, left to right, then the Downloads stack. Edit the list to change it.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

apps=(
  "/System/Applications/Apps.app"
  "/Applications/Google Chrome.app"
  "/System/Applications/Messages.app"
  "/Applications/BusyCal.app"
  "/Applications/Things3.app"
  "/Applications/1Password.app"
  "/Applications/iTerm.app"
  "/Applications/Tailscale.app"
  "/System/Applications/Utilities/Screen Sharing.app"
  "/System/Applications/Music.app"
  "/Applications/Discord.app"
  "/Applications/Claude.app"
  "/Applications/Gemini.app"
  "/System/Applications/Preview.app"
  "/System/Applications/iPhone Mirroring.app"
)

# Keep Spaces in order; hot corners bottom-left app windows, bottom-right Quick Note
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock wvous-bl-corner -int 3
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 14

dockutil --remove all --no-restart
for app in "${apps[@]}"; do
  if [ -e "$app" ]; then dockutil --add "$app" --no-restart; fi
done
dockutil --add "$HOME/Downloads" --section others --display stack --view auto --sort name --no-restart
killall Dock
