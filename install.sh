#!/bin/bash
# Install the dotfiles on this Mac. Safe to run again: links that already
# point into the repo are left alone, and a real file in the way is moved to
# <name>.backup first.
#
# Set SKIP_BREW=1 to only create the links, without Homebrew or Move. Set
# INSTALL_AWDL=1 to only install the daemon that keeps AWDL down for steadier
# Wi-Fi ping (asks for sudo).

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

# The daemon runs as root, so copy it to root-owned files. A symlink into this
# repo would let anything running as this user change what root runs.
if [ "${INSTALL_AWDL:-}" = 1 ]; then
  sudo install -d -o root -g wheel -m 755 /usr/local/sbin
  sudo install -o root -g wheel -m 755 "$DOTFILES/macos/disable_awdl.sh" /usr/local/sbin/disable_awdl.sh
  sudo install -o root -g wheel -m 644 "$DOTFILES/macos/local.disable-awdl.plist" \
    /Library/LaunchDaemons/local.disable-awdl.plist
  sudo launchctl bootout system/local.disable-awdl 2>/dev/null || true
  sudo launchctl bootstrap system /Library/LaunchDaemons/local.disable-awdl.plist
  echo "Installed the daemon that keeps AWDL down"
  exit
fi

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
  case "$name" in brew | claude | macos | zsh) continue ;; esac
  link "$DOTFILES/$name" "$HOME/.config/$name"
done

link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/notify.sh" "$HOME/.claude/notify.sh"
link "$DOTFILES/claude/tab-name.sh" "$HOME/.claude/tab-name.sh"

# My Claude Code skills live in their own repo, cloned to ~/src/skills, under
# skills/<kind>/<name>. The repo is private, so the clone, and later pulls, use
# the kalasjocke account's gh token even when another gh account is active.
if [ ! -d "$HOME/src/skills" ]; then
  git clone -c 'credential.https://github.com.helper=' \
    -c 'credential.https://github.com.helper=!f() { test "$1" = get && echo username=kalasjocke && echo "password=$(gh auth token --user kalasjocke)"; }; f' \
    https://github.com/kalasjocke/skills.git "$HOME/src/skills" ||
    echo "Run install.sh again after gh auth login as kalasjocke to get ~/src/skills"
fi
for dir in "$HOME"/src/skills/skills/*/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name="$(basename "$dir")"
  link "${dir%/}" "$HOME/.claude/skills/$name"
done

# Claude Code writes to its settings file, so start from a copy of the base
if [ ! -e "$HOME/.claude/settings.json" ]; then
  cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  echo "Copied $HOME/.claude/settings.json"
fi

# Teach Claude Code and other agents to use Rex, and have them name the Rex
# session after their task. This adds a hook to the settings copied above.
# Rex puts rex on PATH only in its own terminals.
if command -v rex >/dev/null; then
  rex skill setup --session-naming
else
  echo "Run install.sh again from a Rex terminal to set up Rex's agent skill"
fi

# Build one of my apps from ~/src/<repo> with make, cloning it first if it's
# missing. Skip it when ~/Applications already has it; run make install in its
# folder to update it.
install_app() {
  local repo="$1" app="$2"
  shift 2
  [ -d "$HOME/Applications/$app.app" ] && return
  if [ ! -d "$HOME/src/$repo" ]; then
    git clone "https://github.com/kalasjocke/$repo.git" "$HOME/src/$repo"
  fi
  make -C "$HOME/src/$repo" "$@"
}

# Move moves windows with hotkeys, and Glucose shows the latest Dexcom reading
# in the menu bar. Glucose builds with Xcode, which the Brewfile installs.
if [ "${SKIP_BREW:-}" != 1 ]; then
  install_app move Move cert install
  install_app glucose Glucose cert install
fi

cat <<EOF

Done. Not handled by this script:

- Put machine-specific shell settings in ~/.zshrc.local.
- Add SSH keys to ~/.ssh.
- Log in to gh (gh auth login) and 1Password.
- Turn on Move in System Settings, Device Control and Data Access.
- Log in to Dexcom Share in Glucose's Settings, from its menu bar item.
EOF
