# chezmoi

My dotfiles for two Macs: my MacBook (`laptop`) and a Mac mini that's mostly a homelab and
sometimes a desktop (`mini`). Everything that ends up in your home folder lives in `home/`,
and iTerm2 reads and saves its settings straight from `iterm2/`.

## Setting up a new Mac

1. Sign in to the App Store.
2. Run this and choose `laptop` or `mini` when it asks. It installs Homebrew, all the apps
   and tools, and the dotfiles, so give it a while.
   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$TMPDIR" init --apply --use-builtin-git=true stmio/chezmoi
   ```
3. Open 1Password, sign in, and turn on **Settings → Developer → Integrate with 1Password
   CLI**. Run `chezmoi apply` again to fetch what's kept in 1Password rather than here:
   Berkeley Mono, and the mini's service account token.
4. Restart iTerm2.

## Extra steps for the Mac mini

At the desk, the mini uses 1Password just like the laptop. Claude and remote logins can't
click 1Password's prompts, so they use the `mini-commit-signing` and `mini-vast` SSH keys
from the `Homelab` vault instead, through a service account whose token is saved in
Personal as `Homelab service account`.

1. Turn on the SSH agent in 1Password (Settings → Developer).
2. Run `gh auth login`.
3. Sign in to Tailscale and turn off key expiry for the mini in the admin console.
4. Turn on Remote Login and Screen Sharing (System Settings → General → Sharing), and stop
   it sleeping with `sudo pmset -a sleep 0 autorestart 1`.

Claude asks before it commits, pushes or uses ssh, so approve those from the Claude app.
After a reboot, unlock the mini at its screen, and lock it rather than logging out so
Tailscale and Claude keep running.

## Day to day

- `chezmoi edit ~/.zshrc` edits a dotfile and applies it when you save.
- `chezmoi update` pulls the latest changes and applies them.
- `chezmoi diff` shows anything that's drifted, and `chezmoi re-add <file>` keeps a change
  an app made.
- `chezmoi edit ~/.Brewfile` adds or removes apps.
- macOS settings are in `home/.chezmoiscripts/run_onchange_after_50-macos-settings.sh`.
