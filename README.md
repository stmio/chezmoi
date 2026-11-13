# chezmoi

My dotfiles for two Macs: my MacBook (`laptop`) and a Mac mini that's mostly a homelab and
sometimes a desktop (`mini`). Everything that ends up in your home folder lives in `home/`,
and iTerm2 reads and saves its settings straight from `iterm2/`.

## Setting up a new Mac

1. Sign in to the App Store, and turn on iCloud Drive's *Desktop & Documents Folders*.
2. Run this and choose `laptop` or `mini` when it asks. It installs Homebrew, all the apps
   and tools, and the dotfiles, so give it a while.
   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$TMPDIR" init --apply --use-builtin-git=true stmio/chezmoi
   ```
3. Open 1Password, sign in, and turn on **Settings → Developer → Integrate with 1Password
   CLI**. Then run `chezmoi apply` again in a new terminal window.
4. Restart iTerm2.

## Extra steps for the Mac mini

At the desk, the mini uses 1Password just like the laptop. Claude and remote logins can't
click 1Password's prompts, so they use the `mini-commit-signing` and `mini-vast` SSH keys
from the `Homelab` vault instead.

1. Turn on the SSH agent in 1Password (Settings → Developer).
2. Sign in to Claude Code by running `claude`, and to GitHub with `gh auth login`.
3. Sign in to Tailscale and turn off key expiry for the mini in the admin console.
4. In System Settings, turn on Remote Login and Screen Sharing (General → Sharing), and
   under Energy turn on *Prevent automatic sleeping when the display is off* and set *Start
   up when power is connected* to *After power failure*.

## Day to day

- `chezmoi edit ~/.zshrc` edits a dotfile and applies it when you save.
- `chezmoi update` pulls the latest changes and applies them.
- `chezmoi diff` shows anything that's drifted, and `chezmoi re-add <file>` keeps a change
  an app made.
- `chezmoi edit ~/.Brewfile` adds or removes apps.
- macOS settings and the Dock's apps are set by the scripts in `home/.chezmoiscripts/`.
