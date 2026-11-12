# dotfiles

Managed with [chezmoi](https://chezmoi.io). The dotfiles live in `home/`; `iterm2/` holds
iTerm2's settings, which it reads and writes directly. Two machines, picked on first
`chezmoi init`:

- `laptop`: MacBook. SSH keys and commit signing via the 1Password app.
- `mini`: Mac mini, mostly a headless homelab for Claude, sometimes a desktop. At the
  desk it uses 1Password like the laptop; Claude Code sessions and remote logins use
  separate keys from a 1Password service account, so they work unattended.

## New machine

1. Sign in to the App Store app (needed for the `mas` entries in the Brewfile).
2. Run:
   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$TMPDIR" init --apply --use-builtin-git=true stmio/chezmoi
   ```
   This installs Homebrew if needed (asking for your password), asks which machine it is
   (and for the Warwick usernames used in `~/.ssh/config`), writes the dotfiles, clones
   oh-my-zsh and powerlevel10k, installs everything in `~/.Brewfile`, then rustup, ghcup
   and nvm's Node. The downloaded chezmoi is temporary; the Brewfile installs the real one.
3. Restart iTerm2 so it loads its settings from `iterm2/`.

Berkeley Mono is licensed, so it's kept in 1Password rather than this repo. `chezmoi apply`
installs it from the `Berkeley Mono` document in the Homelab vault whenever it's missing.

## Mac mini

### SSH keys

At the desk, the mini uses the 1Password app's SSH agent and signing key, like the laptop.
Claude Code sessions and remote logins can't, since 1Password asks for approval on the
mini's own screen. They get keys from a dedicated vault instead: `~/.zshenv` switches them
to an agent that `~/.local/bin/homelab-ssh-agent` fills, and points git and jj signing at
the mini key. A tmux session keeps whichever setup it started with.

1. In 1Password on the mini, turn on the SSH agent (Settings → Developer).
2. In 1Password, create a vault named `Homelab` with two SSH Key items,
   `mini-github` and `mini-vast`, and a `Berkeley Mono` document holding a zip of the
   font files (from the laptop: `zip -j BerkeleyMono.zip ~/Library/Fonts/BerkeleyMono*.otf`).
3. Create a service account with read-only access to `Homelab` (Developer → Service
   Accounts). Its vault access can't be changed later, so create the vault first.
4. On the mini, save the token (copied to the clipboard):
   ```sh
   mkdir -p ~/.config/op
   (umask 077; pbpaste > ~/.config/op/homelab-service-account-token)
   ```
5. Over SSH, check `ssh-add -l` lists both keys. Run `chezmoi apply` to install
   Berkeley Mono.
6. GitHub: run `gh auth login`, then add the mini's signing key:
   ```sh
   gh ssh-key add ~/.ssh/mini-github.pub --type signing --title "Mac mini"
   ```
   Check `git push` works over SSH too. gh keeps its login in the keychain, which can be
   locked in SSH sessions; `gh auth login --insecure-storage` keeps it in a file instead.
7. vast.ai: add `~/.ssh/mini-vast.pub` under Account → SSH Keys.

Claude Code on the mini asks before `git commit`, `git push`, `jj git push`, `ssh`, `scp`
and `rsync` (see `home/dot_claude/modify_settings.json`). Approve them from the Claude app
via Remote Control, with "Push when actions required" turned on in `/config`. These rules
match command text, so they aren't a hard security boundary.

### System settings

- Tailscale: `sudo brew services start tailscale && sudo tailscale up`
- System Settings → General → Sharing: turn on Remote Login and Screen Sharing.
- Don't sleep, and restart after a power cut: `sudo pmset -a sleep 0 autorestart 1`
- If FileVault is on, a reboot waits at the login screen for your password before SSH or
  Tailscale come up.

## Day to day

- `chezmoi edit <file>` applies when you close the editor. `chezmoi update` pulls and applies.
- If an app changed a managed file, `chezmoi diff` shows it. Keep the change with
  `chezmoi re-add <file>`, or combine both with `chezmoi merge <file>` (opens nvim).
  Templates (`.tmpl`) and `modify_` files can't be re-added; edit them with `chezmoi edit`.
- Claude Code and gh rewrite their own settings. Only the keys in
  `home/dot_claude/modify_settings.json` and gh's `git_protocol` are managed; the rest is left alone.
- iTerm2 saves straight into `iterm2/`, so its changes show up in `git status`.
- Packages: edit `home/dot_Brewfile.tmpl`. The next `chezmoi apply` runs `brew bundle`.
  `brew bundle cleanup --global` lists anything installed that isn't in it.
- `chezmoi apply -R` updates oh-my-zsh and powerlevel10k now instead of weekly.
- After editing `home/.chezmoi.toml.tmpl`, run `chezmoi init` to regenerate the config.
- `chezmoi managed` lists what's managed; `chezmoi doctor` checks the setup.
