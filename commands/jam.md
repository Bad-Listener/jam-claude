---
description: Toggle NBA Jam sounds and commentary
argument-hint: "[on|off]"
allowed-tools: ["Bash", "Read", "Write"]
---

# JAM Claude Toggle

Enable or disable NBA Jam mode (sounds, spinners, commentary).

Config file: `~/.config/claude/sounds.conf`

$ARGUMENTS

## Instructions

1. Read current state:
   ```bash
   cat ~/.config/claude/sounds.conf 2>/dev/null || echo "SOUND_MODE=off"
   ```

2. If argument is `on` or `off`:
   - `on` → Write `SOUND_MODE=jam` to config file
   - `off` → Write `SOUND_MODE=off` to config file
   - Create `~/.config/claude/` directory if needed

3. Report status with NBA Jam style:
   - Enabled: "🏀 BOOMSHAKALAKA! JAM mode activated!"
   - Disabled: "JAM mode disabled - back to normal"
   - Current (no arg): "Current: JAM mode is ON 🔥" or "Current: JAM mode is OFF"

Example commands:
```bash
# Enable
mkdir -p ~/.config/claude
echo "SOUND_MODE=jam" > ~/.config/claude/sounds.conf

# Disable
echo "SOUND_MODE=off" > ~/.config/claude/sounds.conf

# Check
cat ~/.config/claude/sounds.conf
```
