#!/bin/bash
# Toolchains Homebrew doesn't manage. Each step skips what's already installed.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

# Rust
if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
. "$HOME/.cargo/env"
rustup component add rust-src rust-analyzer
for crate in bat cargo-machete cargo-workspaces tokei tree-sitter-cli; do
  cargo install --list | grep -q "^$crate " || cargo install --locked "$crate"
done

# Haskell
if [ ! -x "$HOME/.ghcup/bin/ghcup" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org |
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh
fi
ghcup="$HOME/.ghcup/bin/ghcup"
for tool_version in ghc:9.4.8 cabal:3.12.1.0 hls:2.9.0.1 stack:3.3.1; do
  tool=${tool_version%%:*} version=${tool_version#*:}
  "$ghcup" whereis "$tool" "$version" >/dev/null 2>&1 || "$ghcup" install "$tool" --set "$version"
done

# Node (nvm.sh doesn't support `set -u`)
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
set +u
. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
node_major=26
nvm which "$node_major" >/dev/null 2>&1 || nvm install "$node_major"
nvm alias default "$node_major" >/dev/null
# Not `nvm use`: it can leave nvm's node behind Homebrew's on PATH
PATH="$(dirname "$(nvm which default)"):$PATH"
set -u
for pkg in pnpm smee-client; do
  npm ls -g "$pkg" >/dev/null 2>&1 || npm install -g "$pkg"
done
