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
   CLI**. Run `chezmoi apply` again to install Berkeley Mono, which lives in 1Password
   rather than here.
4. Restart iTerm2.

## Extra steps for the Mac mini

At the desk, the mini uses 1Password just like the laptop. Claude and remote logins can't
click 1Password's prompts, so they get their own SSH keys from a `Homelab` vault instead.

1. In 1Password, make a `Homelab` vault with two SSH keys, `mini-github` and `mini-vast`.
   Create a read-only service account for it, save its token in your Personal vault as
   `Homelab service account`, and turn on the SSH agent in Settings → Developer.
2. Run `chezmoi apply` to fetch the token, then check `ssh-add -l` over SSH shows both keys.
3. Run `gh auth login` and `gh ssh-key add ~/.ssh/mini-github.pub --type signing`, and add
   `~/.ssh/mini-vast.pub` to your vast.ai account.
4. Sign in to Tailscale and turn off key expiry for the mini in the admin console.
5. Turn on Remote Login and Screen Sharing (System Settings → General → Sharing), and stop
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
