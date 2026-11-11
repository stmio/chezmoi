#!/bin/bash
# Berkeley Mono is licensed, so it lives in 1Password (Homelab vault, document
# "Berkeley Mono") instead of this public repo. Installed only if missing.
set -euo pipefail

fonts="$HOME/Library/Fonts"
compgen -G "$fonts/BerkeleyMono*.otf" >/dev/null && exit 0

token_file="$HOME/.config/op/homelab-service-account-token"
if [ -r "$token_file" ]; then
  OP_SERVICE_ACCOUNT_TOKEN="$(<"$token_file")"
  export OP_SERVICE_ACCOUNT_TOKEN
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if op document get "Berkeley Mono" --vault Homelab --out-file "$tmp/fonts.zip" 2>/dev/null; then
  unzip -qj "$tmp/fonts.zip" '*.otf' -d "$fonts"
else
  echo "Berkeley Mono not installed: couldn't read it from 1Password yet (see README)" >&2
fi
