# Changelog

All notable changes to JAM Claude will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).






## [1.2.0] - 2026-02-15

### Added
- Fire gradient theme — NBA JAM arcade-inspired red-to-gold color palette
- Auto-detecting terminal color support (truecolor → 256-color → basic 16 fallback)
- `NO_COLOR` environment variable support (https://no-color.org/)
- Per-line gradient coloring on the ASCII logo (gold → deep red)
- Unicode double-line borders on the post-game box score (╔═╗║╚╝╠╣)

### Changed
- Banner activation line now gold + bold, version line dim orange
- Fact card stripes now red-orange, category labels gold, text warm white
- Box score borders red-orange, stat labels amber, header gold
- "ON FIRE" indicator now includes 🔥 prefix in fire red
- Install script banner uses 256-color fire gradient

## [1.1.0] - 2026-02-15

### Added
- Commentary frequency settings: `/jam frequent`, `/jam normal`, `/jam low`
- Low mode: milestone-only sounds (streak 2+ only), no notification sounds, critical errors only
- Contextual sound commentary (frequent mode): event-specific sounds for large writes, test passes, big edits, code deletion, and long commands
- Cross-hook state coordination to prevent double sounds when contextual commentary fires

## [1.0.4] - 2026-02-15

### Changed
- Removed demo command from /jam skill

## [1.0.3] - 2026-02-15

### Changed
- Pixel-perfect ASCII art alignment across banner, box score, and fact card

## [1.0.2] - 2026-02-15

### Changed
- Register PostToolUse hook in user settings (fixes box score not displaying)

## [1.0.1] - 2026-02-15

### Changed
- Fix box score not displaying on session exit by writing to /dev/tty instead of stderr

## [1.0.0] - 2026-02-14

### Added
- Sound effects for all hooks (session start, stop, notification, session end)
- Streak tracking with progressive sound unlocks
- Commentary injection via session start context
- `/jam-claude:jam` toggle command (on/off)
