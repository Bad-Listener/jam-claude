# JAM Claude Installation Guide

## Prerequisites

- Claude Code installed and working
- macOS, Linux, or Windows
- Ruby (included with macOS)
- Git

## Quick Install

```bash
git clone https://github.com/Bad-Listener/jam-claude.git \
  ~/.claude/plugins/jam-claude
~/.claude/plugins/jam-claude/install.sh
```

Restart Claude Code. Done!

## What the Install Script Does

The script handles Claude Code's 3-layer plugin registration:

1. **Marketplace registration** (`known_marketplaces.json`) - makes Claude Code aware of the plugin
2. **Install registry** (`installed_plugins.json`) - registers the installed version
3. **Plugin enable** (`settings.json`) - activates the plugin
4. **Cache setup** - copies files to the runtime cache directory
5. **Config** - creates `~/.config/claude/sounds.conf` with `SOUND_MODE=jam`

## Verify Installation

After restarting Claude Code:

1. You should hear "Welcome to NBA Jam!" and see the ASCII banner
2. Type `/jam` to check status
3. Ask Claude a question — you should hear a sound when it finishes responding

## Platform Notes

### macOS

No additional setup needed. Uses built-in `afplay`.

### Linux

Install an audio player:

```bash
# Debian/Ubuntu
sudo apt-get install alsa-utils

# Fedora/RHEL
sudo dnf install alsa-utils

# Arch
sudo pacman -S alsa-utils
```

### Windows

Requires PowerShell (built-in). May need to enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Uninstall

```bash
~/.claude/plugins/jam-claude/uninstall.sh
```

To also remove the source code:

```bash
rm -rf ~/.claude/plugins/jam-claude
```

## Troubleshooting

### No Sounds Playing

1. Check JAM mode enabled: `/jam`
2. Enable if off: `/jam on`
3. Test audio system: `afplay /System/Library/Sounds/Glass.aiff`
4. Check environment: `echo $CLAUDE_DISABLE_SOUNDS` (should be empty)

### Ruby Errors

```bash
ruby --version          # Should show Ruby 2.7+
export RUBY_CLAUDE_HOOKS_DEBUG=1  # Enable debug output
```

### Hooks Not Triggering

1. Restart Claude Code (exit all sessions, reopen)
2. Check install: `cat ~/.claude/plugins/installed_plugins.json | grep jam-claude`
3. Re-run installer: `~/.claude/plugins/jam-claude/install.sh`

### Permission Errors

```bash
chmod +x ~/.claude/plugins/jam-claude/hooks/entrypoints/*.rb
```

## Advanced Configuration

### Adjust Volume

Edit `hooks/lib/sound_player.rb`:

```ruby
"afplay -v 0.3 #{escaped_path}"
#         ^^^
# Change 0.3 to desired volume (0.0-1.0)
```

### Change Sound Mappings

- `hooks/handlers/stop_handler.rb` - Success/completion sounds
- `hooks/handlers/notification_handler.rb` - Notification sounds
- `hooks/handlers/session_end_handler.rb` - Game over sounds

### Reset Streak

```bash
rm ~/.config/claude/jam-streak.json
```

## Getting Help

**Issues:** https://github.com/Bad-Listener/jam-claude/issues
