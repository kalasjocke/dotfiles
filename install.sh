#!/bin/bash
# Install the dotfiles on this Mac. Safe to run again: links that already
# point into the repo are left alone, and a real file in the way is moved to
# <name>.backup first.
#
# Set SKIP_BREW=1 to only create the links.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$1" target="$2"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    mv "$target" "$target.backup"
    echo "Moved $target to $target.backup"
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$src" "$target"
  echo "Linked $target"
}

if [ "${SKIP_BREW:-}" != 1 ]; then
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew bundle --file "$DOTFILES/brew/Brewfile"
fi

link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"

# Every other folder is one app's config folder in ~/.config
for dir in "$DOTFILES"/*/; do
  name="$(basename "$dir")"
  case "$name" in brew | claude | zsh) continue ;; esac
  link "$DOTFILES/$name" "$HOME/.config/$name"
done

link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/notify.sh" "$HOME/.claude/notify.sh"
for dir in "$DOTFILES"/claude/skills/*/; do
  name="$(basename "$dir")"
  link "$DOTFILES/claude/skills/$name" "$HOME/.claude/skills/$name"
done

# Claude Code writes to its settings file, so start from a copy of the base
if [ ! -e "$HOME/.claude/settings.json" ]; then
  cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  echo "Copied $HOME/.claude/settings.json"
fi

cat <<EOF

Done. Not handled by this script:

- Put machine-specific shell settings in ~/.zshrc.local.
- Add SSH keys to ~/.ssh.
- Log in to gh (gh auth login) and 1Password.
EOF
