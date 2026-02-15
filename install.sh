#!/usr/bin/env bash
# JAM Claude Installer
# Sets up the 3-layer plugin registration for Claude Code
set -euo pipefail

PLUGIN_NAME="jam-claude"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_VERSION=$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0]))["version"]' "$SOURCE_DIR/.claude-plugin/plugin.json")
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces/$PLUGIN_NAME"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
CYAN='\033[96m'
BOLD='\033[1m'
RESET='\033[0m'

banner() {
  # Fire gradient: gold(220) → amber(214) → orange(208) → dark_orange(208) → red_orange(202) → deep_red(160)
  echo ""
  echo -e "\033[38;5;220m       ███╗   ██╗██████╗  █████╗          ██╗ █████╗ ███╗   ███╗${RESET}"
  echo -e "\033[38;5;214m       ████╗  ██║██╔══██╗██╔══██╗         ██║██╔══██╗████╗ ████║${RESET}"
  echo -e "\033[38;5;208m       ██╔██╗ ██║██████╔╝███████║         ██║███████║██╔████╔██║${RESET}"
  echo -e "\033[38;5;208m       ██║╚██╗██║██╔══██╗██╔══██║    ██   ██║██╔══██║██║╚██╔╝██║${RESET}"
  echo -e "\033[38;5;202m       ██║ ╚████║██████╔╝██║  ██║    ╚█████╔╝██║  ██║██║ ╚═╝ ██║${RESET}"
  echo -e "\033[38;5;160m       ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝     ╚════╝ ╚═╝  ╚═╝╚═╝     ╚═╝${RESET}"
  echo ""
  echo -e "                      ${BOLD}JAM Claude Installer${RESET}"
  echo ""
}

info()    { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}!${RESET} $1"; }
error()   { echo -e "  ${RED}✗${RESET} $1"; exit 1; }
step()    { echo -e "  ${CYAN}→${RESET} $1"; }

# Check prerequisites
check_prereqs() {
  command -v ruby >/dev/null 2>&1 || error "Ruby not found. Install Ruby first."

  if [[ "$(uname)" == "Darwin" ]]; then
    command -v afplay >/dev/null 2>&1 || warn "afplay not found — sounds won't play on macOS"
  elif [[ "$(uname)" == "Linux" ]]; then
    if ! command -v aplay >/dev/null 2>&1 && ! command -v paplay >/dev/null 2>&1 && ! command -v ffplay >/dev/null 2>&1; then
      warn "No audio player found (aplay, paplay, or ffplay) — sounds won't play on Linux"
      warn "Install one: sudo apt-get install alsa-utils (Debian/Ubuntu)"
    fi
  fi

  [ -d "$CLAUDE_DIR" ] || error "Claude Code not found (~/.claude missing). Install Claude Code first."
}

# Helper: merge JSON key into file using ruby (no jq dependency)
json_merge_key() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [ ! -f "$file" ]; then
    echo "{}" > "$file"
  fi

  ruby -rjson -e '
    file = ARGV[0]
    key = ARGV[1]
    value = JSON.parse(ARGV[2])
    data = JSON.parse(File.read(file))
    data[key] = value
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$file" "$key" "$value"
}

# Helper: merge into installed_plugins.json (v2 format with "plugins" wrapper)
installed_plugins_merge() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [ ! -f "$file" ]; then
    echo '{"version":2,"plugins":{}}' > "$file"
  fi

  ruby -rjson -e '
    file = ARGV[0]
    key = ARGV[1]
    value = JSON.parse(ARGV[2])
    data = JSON.parse(File.read(file))
    data["plugins"] ||= {}
    data["plugins"][key] = value
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$file" "$key" "$value"
}

# Helper: merge enabledPlugins in settings.json
settings_enable_plugin() {
  local file="$1"
  local plugin_key="$2"

  if [ ! -f "$file" ]; then
    echo '{}' > "$file"
  fi

  ruby -rjson -e '
    file = ARGV[0]
    key = ARGV[1]
    data = JSON.parse(File.read(file))
    data["enabledPlugins"] ||= {}
    data["enabledPlugins"][key] = true
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$file" "$plugin_key"
}

# Layer 1: Marketplace registration
setup_marketplace() {
  step "Registering marketplace..."

  # Add to known_marketplaces.json
  json_merge_key "$PLUGINS_DIR/known_marketplaces.json" "$PLUGIN_NAME" \
    "{\"source\":{\"source\":\"git\",\"url\":\"https://github.com/Bad-Listener/jam-claude.git\"},\"installLocation\":\"$MARKETPLACE_DIR\",\"lastUpdated\":\"$TIMESTAMP\"}"

  # Create marketplace directory with manifest
  mkdir -p "$MARKETPLACE_DIR/.claude-plugin"
  cat > "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" <<MANIFEST
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "$PLUGIN_NAME",
  "version": "$PLUGIN_VERSION",
  "description": "NBA Jam sound effects and commentary for Claude Code",
  "owner": {
    "name": "Bad-Listener",
    "url": "https://github.com/Bad-Listener"
  },
  "plugins": [
    {
      "name": "$PLUGIN_NAME",
      "description": "NBA Jam sound effects and commentary for Claude Code",
      "version": "$PLUGIN_VERSION",
      "source": "./jam-claude-plugin",
      "license": "MIT",
      "category": "fun",
      "keywords": ["sounds", "nba-jam", "audio", "fun", "boomshakalaka"]
    }
  ]
}
MANIFEST

  # Create marketplace plugin source (symlink to cache)
  mkdir -p "$MARKETPLACE_DIR/jam-claude-plugin"

  info "Marketplace registered"
}

# Layer 2: Install registry
setup_install_registry() {
  step "Adding to install registry..."

  local git_sha="manual-install"
  if command -v git >/dev/null 2>&1 && [ -d "$SOURCE_DIR/.git" ]; then
    git_sha=$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo "manual-install")
  fi

  installed_plugins_merge "$PLUGINS_DIR/installed_plugins.json" "$PLUGIN_NAME@$PLUGIN_NAME" \
    "[{\"scope\":\"user\",\"installPath\":\"$CACHE_DIR\",\"version\":\"$PLUGIN_VERSION\",\"installedAt\":\"$TIMESTAMP\",\"lastUpdated\":\"$TIMESTAMP\",\"gitCommitSha\":\"$git_sha\"}]"

  info "Install registry updated"
}

# Layer 3: Enable in settings
setup_settings() {
  step "Enabling plugin..."

  settings_enable_plugin "$CLAUDE_DIR/settings.json" "$PLUGIN_NAME@$PLUGIN_NAME"

  info "Plugin enabled in settings"
}

# Register PostToolUse hook in user settings
# Claude Code ignores PostToolUse hooks from plugin hooks.json — only settings.json works
setup_settings_hooks() {
  step "Registering PostToolUse hook..."

  ruby -rjson -e '
    file = ARGV[0]
    cmd  = ARGV[1]

    data = File.exist?(file) ? JSON.parse(File.read(file)) : {}
    data["hooks"] ||= {}
    data["hooks"]["PostToolUse"] ||= []

    # Skip if our hook is already registered
    already = data["hooks"]["PostToolUse"].any? { |group|
      (group["hooks"] || []).any? { |h| h["command"] == cmd }
    }

    unless already
      data["hooks"]["PostToolUse"] << {
        "hooks" => [{ "type" => "command", "command" => cmd }]
      }
      File.write(file, JSON.pretty_generate(data) + "\n")
    end
  ' "$CLAUDE_DIR/settings.json" \
    "$MARKETPLACE_DIR/jam-claude-plugin/hooks/entrypoints/post_tool_use.rb"

  info "PostToolUse hook registered in settings"
}

# Copy plugin files to cache (what Claude Code actually runs)
setup_cache() {
  step "Setting up plugin cache..."

  mkdir -p "$CACHE_DIR"

  # Copy all plugin files to cache (using cp instead of rsync for portability)
  rm -rf "${CACHE_DIR:?}/"*
  cp -a "$SOURCE_DIR/." "$CACHE_DIR/"
  rm -rf "$CACHE_DIR/.git" "$CACHE_DIR/install.sh" "$CACHE_DIR/uninstall.sh"

  # Also copy to marketplace source directory
  rm -rf "${MARKETPLACE_DIR:?}/jam-claude-plugin/"*
  cp -a "$SOURCE_DIR/." "$MARKETPLACE_DIR/jam-claude-plugin/"
  rm -rf "$MARKETPLACE_DIR/jam-claude-plugin/.git" "$MARKETPLACE_DIR/jam-claude-plugin/install.sh" "$MARKETPLACE_DIR/jam-claude-plugin/uninstall.sh"

  # Ensure entrypoints are executable
  chmod +x "$CACHE_DIR/hooks/entrypoints/"*.rb
  chmod +x "$MARKETPLACE_DIR/jam-claude-plugin/hooks/entrypoints/"*.rb

  info "Cache populated ($(find "$CACHE_DIR" -type f | wc -l | tr -d ' ') files)"
}

# Create sounds config directory
setup_config() {
  step "Setting up config..."

  mkdir -p "$HOME/.config/claude"

  if [ -f "$HOME/.config/claude/sounds.conf" ]; then
    info "Config already exists ($(cat "$HOME/.config/claude/sounds.conf"))"
  else
    echo "SOUND_MODE=jam" > "$HOME/.config/claude/sounds.conf"
    info "JAM mode enabled by default"
  fi
}

# Main
main() {
  banner
  check_prereqs

  echo -e "  ${BOLD}Installing JAM Claude v${PLUGIN_VERSION}...${RESET}"
  echo ""

  setup_marketplace
  setup_install_registry
  setup_settings
  setup_cache
  setup_settings_hooks
  setup_config

  # Clear stale update notification after fresh install
  rm -f "$HOME/.config/claude/jam-update.json"

  echo ""
  echo -e "  \033[38;5;220m${BOLD}BOOMSHAKALAKA! Installation complete!${RESET}"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo "  1. Restart Claude Code (exit and reopen)"
  echo -e "  2. Type ${CYAN}/jam-claude:jam${RESET} to check status"
  echo -e "  3. Use ${CYAN}/jam-claude:jam on${RESET} or ${CYAN}/jam-claude:jam off${RESET} to toggle"
  echo ""
}

main "$@"
