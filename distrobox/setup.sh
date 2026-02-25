#!/usr/bin/env bash
# ============================================================================
# setup.sh — Create and configure the "dev" distrobox on Bazzite
#
# Usage:  ~/dotfiles/setup.sh
# Run from the Bazzite HOST (not inside a distrobox).
# ============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOXNAME="dev"
IMAGE="ubuntu:24.04"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[i]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# ──────────────────────────────────────────────────────────────────────────────
# 1. Symlink host-side configs (Ghostty, Git)
# ──────────────────────────────────────────────────────────────────────────────
setup_host_symlinks() {
    info "Setting up host-side symlinks..."

    # Ghostty
    mkdir -p ~/.config/ghostty
    ln -sf "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
    log "Ghostty config linked"

    # Git — distrobox shares the host home dir, so ~/.gitconfig works as-is.
    # Add a symlink here if you later create a dotfiles/git/gitconfig file.
    log "Git config: using existing host ~/.gitconfig"
}

# ──────────────────────────────────────────────────────────────────────────────
# 2. Create the distrobox
# ──────────────────────────────────────────────────────────────────────────────
create_box() {
    if distrobox list | grep -q "$BOXNAME"; then
        warn "Distrobox '$BOXNAME' already exists. Skipping creation."
    else
        info "Creating distrobox '$BOXNAME' from $IMAGE..."
        distrobox create --name "$BOXNAME" --image "$IMAGE" --yes \
            --pre-init-hooks "userdel -r ubuntu 2>/dev/null || true"
        log "Distrobox '$BOXNAME' created"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 3. Bootstrap everything inside the distrobox
# ──────────────────────────────────────────────────────────────────────────────
bootstrap_inside() {
    info "Bootstrapping inside '$BOXNAME'... (this will take a few minutes)"

    distrobox enter "$BOXNAME" -- bash -c "$(cat <<'INNER_SCRIPT'
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo ">>> Updating system..."
sudo apt update && sudo apt upgrade -y

# ── Core packages ──────────────────────────────────────────────────────────
echo ">>> Installing core packages..."
sudo apt install -y \
    build-essential git curl wget unzip \
    zsh \
    python3 python3-pip python3-venv \
    openssh-client \
    bat fd-find \
    software-properties-common

# ── fzf ────────────────────────────────────────────────────────────────────
echo ">>> Installing fzf..."
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
fi

# ── ripgrep ────────────────────────────────────────────────────────────────
echo ">>> Installing ripgrep..."
sudo apt install -y ripgrep 2>/dev/null || {
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb
    sudo dpkg -i ripgrep_14.1.1-1_amd64.deb
    rm -f ripgrep_14.1.1-1_amd64.deb
}

# ── eza (modern ls) ───────────────────────────────────────────────────────
echo ">>> Installing eza..."
if ! command -v eza &>/dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    sudo apt update
    sudo apt install -y eza
fi

# ── zoxide ─────────────────────────────────────────────────────────────────
echo ">>> Installing zoxide..."
if ! command -v zoxide &>/dev/null; then
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# ── lazygit ────────────────────────────────────────────────────────────────
echo ">>> Installing lazygit..."
if ! command -v lazygit &>/dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
fi

# ── Oh My Zsh ──────────────────────────────────────────────────────────────
echo ">>> Installing Oh My Zsh..."
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# OMZ plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Custom theme
mkdir -p "$ZSH_CUSTOM/themes"
ln -sf "$DOTFILES_DIR/zsh/arrow-custom.zsh-theme" "$ZSH_CUSTOM/themes/arrow-custom.zsh-theme"

# ── NVM + Node.js ──────────────────────────────────────────────────────────
echo ">>> Installing nvm + Node.js LTS..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="${NVM_DIR:-$HOME/.config/nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install --lts

# ── Neovim ─────────────────────────────────────────────────────────────────
echo ">>> Installing Neovim..."
if ! command -v nvim &>/dev/null; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f nvim-linux-x86_64.tar.gz
fi

# kickstart.nvim
echo ">>> Setting up kickstart.nvim..."
if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
fi

# ── Google Cloud CLI ──────────────────────────────────────────────────────
echo ">>> Installing Google Cloud CLI..."
if ! command -v gcloud &>/dev/null; then
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update && sudo apt-get install -y google-cloud-cli
fi

# ── uv (Python package manager) ───────────────────────────────────────────
echo ">>> Installing uv..."
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ── Bruin CLI ─────────────────────────────────────────────────────────
echo ">>> Installing Bruin CLI..."
if ! command -v bruin &>/dev/null; then
    curl -LsSf https://getbruin.com/install/cli | sh
fi

# ── Claude Code ────────────────────────────────────────────────────────────
echo ">>> Installing Claude Code..."
if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

# Claude Code settings
mkdir -p "$HOME/.claude"
if [ -f "$DOTFILES_DIR/claude-code/settings.json" ]; then
    ln -sf "$DOTFILES_DIR/claude-code/settings.json" "$HOME/.claude/settings.json"
fi

# ── Symlink zshrc ──────────────────────────────────────────────────────────
echo ">>> Linking zshrc..."
ln -sf "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# ── Set default shell to zsh ──────────────────────────────────────────────
echo ">>> Setting zsh as default shell..."
sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true

echo ""
echo "============================================"
echo "  Dev environment setup complete!"
echo "  Exit and re-enter the distrobox:"
echo "    distrobox enter dev"
echo "============================================"

INNER_SCRIPT
)"
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║     Dotfiles Setup — Bazzite + Distrobox     ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    # Check we're on the host
    if [ -f /run/.containerenv ]; then
        err "This script should be run from the Bazzite HOST, not inside a container."
        exit 1
    fi

    setup_host_symlinks
    create_box
    bootstrap_inside

    echo ""
    log "All done! Enter your dev environment with:"
    echo "    distrobox enter dev"
    echo ""
    info "Git and SSH are shared from the host automatically."
    info "To authenticate Claude Code, run 'claude' inside the distrobox."
    echo ""
}

main "$@"
