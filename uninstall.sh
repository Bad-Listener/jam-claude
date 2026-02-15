#!/usr/bin/env bash
# JAM Claude Uninstaller
# Removes all 3 registration layers and config files
set -euo pipefail

PLUGIN_NAME="jam-claude"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"

RED='\033[91m'
GREEN='\033[92m'
CYAN='\033[96m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "  ${GREEN}✓${RESET} $1"; }
step()  { echo -e "  ${CYAN}→${RESET} $1"; }

echo ""
echo -e "  ${BOLD}Uninstalling JAM Claude...${RESET}"
echo ""

# Remove from known_marketplaces.json
step "Removing marketplace entry..."
if [ -f "$PLUGINS_DIR/known_marketplaces.json" ]; then
  ruby -rjson -e '
    file = ARGV[0]
    data = JSON.parse(File.read(file))
    data.delete("jam-claude")
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$PLUGINS_DIR/known_marketplaces.json"
  info "Marketplace entry removed"
fi

# Remove from installed_plugins.json
step "Removing install registry entry..."
if [ -f "$PLUGINS_DIR/installed_plugins.json" ]; then
  ruby -rjson -e '
    file = ARGV[0]
    data = JSON.parse(File.read(file))
    (data["plugins"] || data).delete("jam-claude@jam-claude")
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$PLUGINS_DIR/installed_plugins.json"
  info "Install registry entry removed"
fi

# Remove from settings.json
step "Removing from enabled plugins..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  ruby -rjson -e '
    file = ARGV[0]
    data = JSON.parse(File.read(file))
    (data["enabledPlugins"] || {}).delete("jam-claude@jam-claude")
    File.write(file, JSON.pretty_generate(data) + "\n")
  ' "$CLAUDE_DIR/settings.json"
  info "Plugin disabled in settings"
fi

# Remove PostToolUse hook from settings.json
step "Removing PostToolUse hook from settings..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  ruby -rjson -e '
    file = ARGV[0]
    marker = ARGV[1]

    data = JSON.parse(File.read(file))
    hooks = data.dig("hooks", "PostToolUse")
    if hooks.is_a?(Array)
      hooks.reject! { |group|
        (group["hooks"] || []).any? { |h| h["command"]&.include?(marker) }
      }

      # Clean up empty array / empty hooks hash
      data["hooks"].delete("PostToolUse") if hooks.empty?
      data.delete("hooks") if data["hooks"]&.empty?

      File.write(file, JSON.pretty_generate(data) + "\n")
    end
  ' "$CLAUDE_DIR/settings.json" "jam-claude"
  info "PostToolUse hook removed from settings"
fi

# Remove cache
step "Removing cache..."
rm -rf "$PLUGINS_DIR/cache/$PLUGIN_NAME"
info "Cache removed"

# Remove marketplace directory
step "Removing marketplace directory..."
rm -rf "$PLUGINS_DIR/marketplaces/$PLUGIN_NAME"
info "Marketplace directory removed"

# Remove config files
step "Removing config files..."
rm -f "$HOME/.config/claude/sounds.conf"
rm -f "$HOME/.config/claude/jam-streak.json"
rm -f "$HOME/.config/claude/jam-stats.json"
info "Config files removed"

echo ""
echo -e "  ${GREEN}${BOLD}JAM Claude uninstalled.${RESET}"
echo ""
echo "  To also remove the source code:"
echo -e "  ${RED}rm -rf $PLUGINS_DIR/$PLUGIN_NAME${RESET}"
echo ""
