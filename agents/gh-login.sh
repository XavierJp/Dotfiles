#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.config/agent/env"
gh token generate --app-id "$GH_APP_ID" --installation-id "$GH_APP_INSTALLATION_ID" \
  --key "$GH_APP_KEY" --token-only | gh auth login --with-token
gh auth setup-git
