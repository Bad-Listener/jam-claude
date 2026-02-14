# JAM Claude Installation Guide

Detailed installation instructions for JAM Claude plugin.

## Prerequisites

- Claude Code installed and working
- macOS, Linux, or Windows
- Git (for manual installation)

## Method 1: Plugin System (Recommended)

**Coming soon** - will be available via Claude Code plugin marketplace.

```bash
claude plugin install jam-claude
/jam on
```

## Method 2: Manual Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/Bad-Listener/jam-claude.git \
  ~/.claude/plugins/jam-claude
```

### Step 2: Verify Installation

```bash
ls ~/.claude/plugins/jam-claude/
```

Expected output:
```
README.md
LICENSE
hooks/
vendor/
commands/
lib/
.claude-plugin/
```

### Step 3: Check Sounds Installed

```bash
ls ~/.claude/plugins/jam-claude/vendor/sounds/ | wc -l
```

Expected: `90+` sound files

### Step 4: Verify Hooks Registration

```bash
cat ~/.claude/plugins/jam-claude/hooks/hooks.json
```

Should show SessionStart, Stop, Notification, SessionEnd hooks.

### Step 5: Restart Claude Code

Exit any running Claude Code sessions and start a new one.

### Step 6: Enable JAM Mode

```bash
/jam on
```

Expected output: "BOOMSHAKALAKA! JAM mode activated!"

### Step 7: Test Sound Playback

Start a new session - you should hear "Welcome to NBA Jam!"

If no sound, see Troubleshooting below.

## Platform-Specific Notes

### macOS

No additional setup needed. Uses built-in `afplay`.

### Linux

Install audio player:

**Debian/Ubuntu:**
```bash
sudo apt-get install alsa-utils
```

**Fedora/RHEL:**
```bash
sudo dnf install alsa-utils
```

**Arch:**
```bash
sudo pacman -S alsa-utils
```

### Windows

Requires PowerShell (built-in). May need to enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Uninstallation

### Disable JAM Mode

```bash
/jam off
```

### Remove Plugin

```bash
rm -rf ~/.claude/plugins/jam-claude
```

### Remove Config

```bash
rm ~/.config/claude/sounds.conf
rm ~/.config/claude/jam-streak.json
```

## Troubleshooting

### No Sounds Playing

**Check JAM mode enabled:**
```bash
cat ~/.config/claude/sounds.conf
```

Should show: `SOUND_MODE=jam`

**Test audio system:**
```bash
# macOS
afplay /System/Library/Sounds/Glass.aiff

# Linux
aplay /usr/share/sounds/alsa/Front_Center.wav
```

**Check environment:**
```bash
echo $CLAUDE_DISABLE_SOUNDS
```

Should be empty. If set, unset it:
```bash
unset CLAUDE_DISABLE_SOUNDS
```

### Ruby Errors

**Check Ruby installed:**
```bash
ruby --version
```

Should show Ruby 2.7+ (macOS includes Ruby)

**Enable debug mode:**
```bash
export RUBY_CLAUDE_HOOKS_DEBUG=1
```

Check Claude Code output for detailed errors.

### Permission Errors

**Make entrypoints executable:**
```bash
chmod +x ~/.claude/plugins/jam-claude/hooks/entrypoints/*.rb
```

### Hooks Not Triggering

**Check hooks.json exists:**
```bash
cat ~/.claude/plugins/jam-claude/hooks/hooks.json
```

**Restart Claude Code:**
Exit all sessions and start fresh.

## Advanced Configuration

### Adjust Sound Volume

Edit `~/.claude/plugins/jam-claude/hooks/lib/sound_player.rb`:

```ruby
# macOS command
"afplay -v 0.3 #{escaped_path}"
#         ^^^
# Change 0.3 to desired volume (0.0-1.0)
```

### Change Sound Mappings

Edit handler files:
- `hooks/handlers/stop_handler.rb` - Success sounds
- `hooks/handlers/notification_handler.rb` - Notification sounds
- `hooks/handlers/session_end_handler.rb` - End sounds

### Reset Streak

```bash
rm ~/.config/claude/jam-streak.json
```

## Getting Help

**Issues:** https://github.com/Bad-Listener/jam-claude/issues
