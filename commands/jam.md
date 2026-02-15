---
description: Toggle NBA Jam sounds and commentary
argument-hint: "[on|off|frequent|normal|low]"
allowed-tools: ["Bash", "Read", "Write"]
---

# JAM Claude Toggle

Enable or disable NBA Jam mode (sounds, spinners, commentary).

Config file: `~/.config/claude/sounds.conf`

$ARGUMENTS

## Arguments

| Argument | SOUND_MODE | SOUND_FREQUENCY | Description |
|----------|-----------|-----------------|-------------|
| `on` | jam | normal | Enable JAM mode (default frequency) |
| `off` | off | (unchanged) | Disable all sounds |
| `frequent` | jam | frequent | All sounds + contextual commentary |
| `normal` | jam | normal | Standard sound density |
| `low` | jam | low | Milestone sounds only |
| (none) | — | — | Report current mode + frequency |

## Instructions

1. Read current state:
   ```bash
   cat ~/.config/claude/sounds.conf 2>/dev/null || echo "No config found"
   ```

2. Based on the argument:
   - `on` → Write both lines: `SOUND_MODE=jam` and `SOUND_FREQUENCY=normal`
   - `off` → Write `SOUND_MODE=off` (keep existing SOUND_FREQUENCY)
   - `frequent` → Write both lines: `SOUND_MODE=jam` and `SOUND_FREQUENCY=frequent`
   - `normal` → Write both lines: `SOUND_MODE=jam` and `SOUND_FREQUENCY=normal`
   - `low` → Write both lines: `SOUND_MODE=jam` and `SOUND_FREQUENCY=low`
   - No argument → Just report status (don't modify config)
   - Create `~/.config/claude/` directory if needed

3. Report status with NBA Jam style:
   - `on`: "BOOMSHAKALAKA! JAM mode activated!"
   - `off`: "JAM mode disabled - back to normal"
   - `frequent`: "BOOMSHAKALAKA! JAM mode: FREQUENT — Tim Kitzrow is in the booth!"
   - `normal`: "BOOMSHAKALAKA! JAM mode: NORMAL"
   - `low`: "BOOMSHAKALAKA! JAM mode: LOW — milestones only"
   - No arg: "Current: JAM mode is ON (frequency: normal)" or "Current: JAM mode is OFF"

Example commands:
```bash
# Enable with frequency
mkdir -p ~/.config/claude
printf "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n" > ~/.config/claude/sounds.conf

# Enable frequent mode
printf "SOUND_MODE=jam\nSOUND_FREQUENCY=frequent\n" > ~/.config/claude/sounds.conf

# Enable low mode
printf "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n" > ~/.config/claude/sounds.conf

# Disable
printf "SOUND_MODE=off\nSOUND_FREQUENCY=normal\n" > ~/.config/claude/sounds.conf

# Check
cat ~/.config/claude/sounds.conf
```
