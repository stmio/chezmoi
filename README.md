# chezmoi

Dotfiles for two Macs, managed with [chezmoi](https://chezmoi.io): `laptop` (MacBook) and
`mini` (Mac mini homelab, sometimes a desktop). Dotfiles are in `home/`; iTerm2 keeps its
settings in `iterm2/`.

## Set up a Mac

1. Sign in to the App Store.
2. Run this and pick `laptop` or `mini`. It installs Homebrew, the Brewfile, toolchains
   and the dotfiles.
   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$TMPDIR" init --apply --use-builtin-git=true stmio/chezmoi
   ```
3. Restart iTerm2.

Aseprite, Kaeru and Tulip have no Homebrew casks, so install them by hand if needed.

## Mac mini extras

At the desk the mini uses 1Password like the laptop. Claude Code and remote logins can't
approve 1Password prompts, so they use keys from a `Homelab` vault instead (a tmux session
keeps whichever it started with).

1. In 1Password, turn on the SSH agent (Settings → Developer). Create a `Homelab` vault
   with SSH keys `mini-github` and `mini-vast`, and a `Berkeley Mono` document holding
   `zip -j BerkeleyMono.zip ~/Library/Fonts/BerkeleyMono*.otf` from the laptop. Then
   create a read-only service account for that vault.
2. Save the service account token from the clipboard:
   ```sh
   mkdir -p ~/.config/op && (umask 077; pbpaste > ~/.config/op/homelab-service-account-token)
   ```
3. Run `chezmoi apply` to install Berkeley Mono, and check `ssh-add -l` over SSH lists both keys.
4. Run `gh auth login` and `gh ssh-key add ~/.ssh/mini-github.pub --type signing`. If
   `git push` fails over SSH, log in again with `--insecure-storage`. Add
   `~/.ssh/mini-vast.pub` to vast.ai.
5. Log in to Tailscale and turn off the mini's key expiry in the
   [admin console](https://login.tailscale.com/admin/machines).
6. Turn on Remote Login and Screen Sharing (System Settings → General → Sharing), then
   run `sudo pmset -a sleep 0 autorestart 1`.

Claude asks before committing, pushing or using ssh; approve from the Claude app. After a
reboot, unlock the mini at its screen, and lock it rather than logging out.

## Day to day

| To | Run |
|---|---|
| Edit a dotfile (applies on save) | `chezmoi edit ~/.zshrc` |
| Pull and apply | `chezmoi update` |
| See local changes | `chezmoi diff` |
| Keep an app's change | `chezmoi re-add <file>` (not templates) or `chezmoi merge <file>` |
| Add a package | `chezmoi edit ~/.Brewfile` |
| Change macOS settings | edit `home/.chezmoiscripts/run_onchange_after_50-macos-settings.sh` |
| Update oh-my-zsh and powerlevel10k | `chezmoi apply -R` |
| Regenerate config after editing `.chezmoi.toml.tmpl` | `chezmoi init` |
