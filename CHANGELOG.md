# Changelog

All notable changes to JAM Claude will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).





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
