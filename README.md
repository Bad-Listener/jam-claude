# JAM Claude 🏀

> **BOOMSHAKALAKA!** NBA Jam sound effects and commentary for Claude Code

Bring the legendary energy of NBA Jam to your coding sessions. Every command becomes a basketball game with classic commentator sounds, on-fire streaks, and boomshakalaka moments.

## Features

🔊 **NBA Jam Sound Effects**
- Session start: "Welcome to NBA Jam!"
- Success: "It's Good!", "From Downtown!", "Monster Jam!"
- On fire: "He's on Fire!" (unlocks at 3+ streak)
- Notifications: Whistles, buzzers, horns
- Game over: "Wins The Game!"

🎯 **Custom Spinners**
- Reading files: "From Downtown!"
- Writing code: "He's Heating Up!"
- Running tests: "Razzle Dazzle!"
- Git operations: "Monster Jam!"
- Bash commands: "Boomshakalaka!"

🔥 **Streak Tracking**
- Consecutive successes build your streak
- 3+ streak: "He's on Fire!" sound unlocked
- 5+ streak: Increased fire chance
- Failures reset the streak

💬 **Commentator Quips**
- Claude occasionally uses NBA Jam phrases
- "BOOMSHAKALAKA!" after impressive solutions
- "From downtown!" for elegant code
- Natural, not forced

## Installation

### Via Claude Code Plugin System (Coming Soon)

```bash
claude plugin install jam-claude
```

### Manual Installation

1. Clone to plugins directory:
```bash
git clone https://github.com/Bad-Listener/jam-claude.git \
  ~/.claude/plugins/jam-claude
```

2. Restart Claude Code

3. Enable JAM mode:
```bash
/jam on
```

## Usage

### Toggle JAM Mode

```bash
/jam on      # Enable JAM Claude
/jam off     # Disable JAM Claude
/jam         # Show current status
```

### During Sessions

Just use Claude Code normally! JAM Claude adds:
- Sound effects for events
- NBA Jam spinner phrases
- Occasional commentary in responses
- Streak tracking across commands

## Configuration

**Config file:** `~/.config/claude/sounds.conf`

```bash
SOUND_MODE=jam    # Enable JAM mode
SOUND_MODE=off    # Disable JAM mode
```

**Environment override:**
```bash
export CLAUDE_DISABLE_SOUNDS=1  # Force disable all sounds
```

## Requirements

- **Platform:** macOS (primary), Linux (aplay/paplay), Windows (Media.SoundPlayer)
- **Audio:** `afplay` on macOS (built-in)
- **Ruby:** Included with macOS

## Sounds Included

90+ NBA Jam audio clips including:
- Welcome to NBA Jam
- He's on Fire
- Heating Up
- From Downtown
- Monster Jam
- Boomshakalaka
- Razzle Dazzle
- Kaboom
- Rejected
- Wins The Game
- And many more!

## How It Works

JAM Claude uses Claude Code's hooks system:

1. **SessionStart**: Welcome banner + sound
2. **Stop**: Success sounds with streak weighting
3. **Notification**: Referee sounds (whistles, buzzers)
4. **SessionEnd**: Game over sounds

Spinner customization via system prompt injection.

## Troubleshooting

**No sounds playing?**
1. Check JAM mode: `/jam`
2. Enable if off: `/jam on`
3. Test audio: `afplay /System/Library/Sounds/Glass.aiff`
4. Check env: `echo $CLAUDE_DISABLE_SOUNDS` (should be empty)

**Sounds too loud/quiet?**
- Edit `hooks/lib/sound_player.rb`
- Change volume: `afplay -v 0.3` (0.0-1.0)

**Ruby errors?**
```bash
# Check Ruby available
ruby --version

# Debug mode
export RUBY_CLAUDE_HOOKS_DEBUG=1
```

## Credits

**Inspiration:** [Age of Claude](https://github.com/kylesnowschwartz/age-of-claude) by Kyle Snow Schwartz

**Sounds:** NBA Jam (Midway, 1993)

**Author:** Andreas Giannopoulos

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

Contributions welcome! Please:
1. Fork the repo
2. Create a feature branch
3. Test thoroughly
4. Submit a PR

## Changelog

### 1.0.0 (2026-02-14)
- Initial release
- Sound effects for all hooks
- Spinner customization
- Streak tracking
- Commentary injection
- /jam toggle command
