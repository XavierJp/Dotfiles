# dotfiles

.files for an easy macOS config

## Prerequisites

- [Homebrew](https://brew.sh)
- [Oh My Zsh](https://ohmyz.sh)

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Installation

Clone the repo:

```bash
git clone git@github.com:parsio-ai/dotfiles.git ~/dotfiles
```

### Zsh

```bash
# Symlink zshrc
ln -sf ~/dotfiles/zsh/zshrc ~/.zshrc

# Install custom theme
ln -sf ~/dotfiles/zsh/arrow-custom.zsh-theme ~/.oh-my-zsh/custom/themes/arrow-custom.zsh-theme

# Install optional dependencies
brew install autojump nvm

# Reload shell
source ~/.zshrc
```

### iTerm2

```bash
# Install iTerm2
brew install --cask iterm2

# Configure iTerm2 to use dotfiles preferences
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

Then restart iTerm2.

## Structure

```
dotfiles/
├── iterm2/
│   └── com.googlecode.iterm2.plist  # iTerm2 preferences (colors, profiles, etc.)
└── zsh/
    ├── zshrc                        # Zsh configuration
    └── arrow-custom.zsh-theme       # Custom Oh My Zsh theme
```

## Local overrides

For machine-specific secrets or settings, create `~/.zshrc.local` (not tracked in git).
