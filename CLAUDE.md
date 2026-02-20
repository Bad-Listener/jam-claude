# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JAM Claude is a Claude Code plugin that plays NBA Jam (1993 arcade) sound effects and commentary during coding sessions. It uses Claude Code's hook system to trigger sounds on session events, tracks streaks of successful operations, detects errors with category-specific sounds, and injects NBA Jam commentary into responses. 31 unique sounds across 6 categories.

## Architecture

### Code Flow

Five hooks registered in `hooks/hooks.json`, each following the pattern:

```
hooks/entrypoints/<event>.rb  →  hooks/handlers/<event>_handler.rb  →  hooks/lib/*.rb
```

- **Entrypoints** parse stdin JSON and delegate to handlers
- **Handlers** extend `ClaudeHooks::*` base classes from vendored DSL (`vendor/claude_hooks/`)
- **Lib modules** provide cross-cutting concerns (sound playback, streak tracking, error detection, stats, theming)

### Hook System (5 Hooks)

| Hook | Trigger | Behavior |
|------|---------|----------|
| `session_start` | Session opens | ASCII banner + welcome sound + inject commentary context + reset stats + background update check |
| `post_tool_use` | After any tool call | Record stats + detect errors + play contextual sounds (frequent mode) + coordinate state with Stop hook |
| `stop` | Claude finishes responding | Increment streak (if no error) + play weighted success sound (unless error or contextual sound already played) |
| `notification` | Permission/idle/elicitation | Play referee sound (whistle/buzz/horn) + increment blocks stat |
| `session_end` | Session closes | Play game-over sound based on exit reason + display box score (if points > 0) |

### PostToolUse Hook (Detailed)

The PostToolUse hook is the most complex — it bridges tool execution and the Stop hook:

1. **Stat recording:** Every tool use earns points + a category-specific stat (Edit → assists, Read/Grep/Glob → rebounds, Write → dunks, Bash → steals)
2. **Error detection:** Scans tool response for errors via `ErrorDetector` → maps to category-specific error sounds via `ErrorSoundMapper` → resets streak → marks `ErrorState` so Stop hook skips success sound → increments turnovers
3. **Contextual sounds (frequent mode only):** Detects special events and plays thematic sounds:
   - Large file write (>100 lines) → "Monster Jam" / "Slams It"
   - Successful test run → "Scores" / "It's Good"
   - Big edit (>20 line replacement) → "Razzle Dazzle"
   - Code deletion (net -10+ lines) → "Kaboom"
   - Long successful command (>50 lines output) → "From Downtown"
4. **State coordination:** Marks `ContextualSoundState` when contextual sound fires, so Stop hook doesn't double-play

### Cross-Hook State Coordination

Two state files prevent double sounds in the same turn:

| State File | Writer | Reader | Purpose |
|------------|--------|--------|---------|
| `jam-error-state.json` | PostToolUse (on error) | Stop (skips success sound) | Prevent error + success in same turn |
| `jam-contextual-state.json` | PostToolUse (on contextual sound) | Stop (skips success sound) | Prevent contextual + generic success in same turn |

Both use atomic temp-file-then-rename writes and read-then-clear semantics.

### Streak Progression

Streak state persists in `~/.config/claude/jam-streak.json` using atomic temp-file-then-rename writes.

**Normal/frequent mode:**
- Streak 0-1: Base sound pool (11 sounds, weighted)
- Streak 2: "Heating Up" guaranteed
- Streak 3-4: Base pool + "He's on Fire" (15%)
- Streak 5+: Base pool + "He's on Fire" (30%)

**Low mode (simplified):**
- Streak 0-1: No sound
- Streak 2: "Heating Up" 100%
- Streak 3+: "He's on Fire" 100%

### Error Detection System

`ErrorDetector` categorizes errors from tool responses by exit code and content patterns:

| Category | Trigger | Sound |
|----------|---------|-------|
| `permission_denied` | EACCES, "unauthorized" | "Rejected" |
| `file_not_found` | ENOENT, "no such file" | "Off the Rim" |
| `exit_failure` | Exit codes 1-125 | "Terrible Shot" / "No Good" |
| `command_not_found` | Exit code 127 | "Wild Shot" |
| `signal_termination` | Exit codes 128-255 | "Shove" |
| `network_error` | Connection/timeout/DNS | "Intercepted" |
| `syntax_error` | Parse errors | "Ugly Shot" |
| `state_corruption` | Corrupt/integrity errors | "The Turnover" |
| `generic_error` | Unclassified fallback | "No Good" / "Wild Shot" |

In low mode, only critical errors play sounds (`permission_denied`, `signal_termination`, `state_corruption`).

### Session Stats (Basketball Stats)

`SessionStats` tracks tool usage as basketball stats in `~/.config/claude/jam-stats.json`:

| Stat | Source |
|------|--------|
| Points | Every tool use |
| Assists | Edit tool |
| Rebounds | Read/Grep/Glob tools |
| Dunks | Write tool |
| Steals | Bash tool |
| Blocks | Permission prompts |
| Turnovers | Errors/failures |
| Peak Streak | Highest streak in session |

Box score displayed at session end with 5 rating tiers: Hall of Fame (51+), MVP Candidate (31-50), All-Star (16-30), Starter (6-15), Benchwarmer (0-5).

### NBA Facts System

`NbaFacts` contains 175+ curated facts across 6 categories, each with an emoji identifier:
- `jam_arcade` (54) — Original 1993 arcade trivia
- `jam_franchise` (25) — Sequels, ports, revivals
- `jam_culture` (20) — Cultural impact, revenue, influence
- `iconic_moments` (41) — Historic NBA moments
- `player_quotes` (30) — Legendary player quotes
- `oddities` (26) — Bizarre NBA history

Displayed at session start via `FactPresenter` (TikTok-style formatting with category labels, bold keywords, random reactions).

### Fire Gradient Theme

`FireColors` provides the arcade-inspired fire palette (red → gold) with auto-detecting terminal capability:
1. **Truecolor** (24-bit RGB) — `COLORTERM=truecolor` or `TERM=*-256color`
2. **256-color** (8-bit) — `TERM=*-256color`
3. **Basic 16-color** — fallback

9 named colors: `gold`, `amber`, `orange`, `dark_orange`, `red_orange`, `deep_red`, `fire_red`, `warm_white`, `dim_orange`. Respects `NO_COLOR` env var (https://no-color.org/).

### Update Checker

`UpdateChecker` runs a background check (forked child process) once per 24 hours, comparing local HEAD against `origin/main`. Results cached in `~/.config/claude/jam-update.json`. Current session reads the cached state from the previous check — zero latency impact. Graceful degradation on platforms without `fork` (Windows/JRuby).

## Configuration

**Config file:** `~/.config/claude/sounds.conf`

Two settings read by `lib/jam_config.rb`:

| Setting | Values | Default |
|---------|--------|---------|
| `SOUND_MODE` | `jam`, `off` | `off` |
| `SOUND_FREQUENCY` | `frequent`, `normal`, `low` | `normal` |

**Methods:** `JamConfig.jam?`, `JamConfig.off?`, `JamConfig.frequent?`, `JamConfig.normal?`, `JamConfig.low?`

**Env override:** `CLAUDE_DISABLE_SOUNDS=1` takes precedence over config file.

**Sound modes:**

| Mode | Behavior |
|------|----------|
| `off` | Entire theme disabled — no sounds, no banner, no commentary, no stats, no box score. Only the background update checker runs. |
| `jam` | Theme enabled — behavior controlled by `SOUND_FREQUENCY` setting below |

**Frequency modes** (only apply when `SOUND_MODE=jam`):

| Mode | Description | Behavior |
|------|-------------|----------|
| `frequent` | Tim Kitzrow Mode | All sounds + contextual commentary on PostToolUse |
| `normal` | Standard | Success/error/notification sounds, no contextual commentary |
| `low` | Milestone only | Success sounds at streak 2+ only, no notification sounds, critical errors only |

## Sound Library

31 unique sounds in `vendor/sounds/` across 6 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Startup | 3 | Welcome to NBA Jam (65%), Hello (20%), Tonight's Matchup (15%) |
| Success | 11 | It's Good, From Downtown, Monster Jam, Kaboom, Razzle Dazzle, etc. |
| Streak | 2 | Heating Up, He's on Fire |
| Error | 9 | Rejected, Off the Rim, Terrible Shot, No Good, Wild Shot, etc. |
| Notification | 3 | Whistle (permission), Buzz (idle), Horn (elicitation) |
| Game Over | 3 | Wins The Game (exit), At the Buzzer (clear), Overtime (prompt exit) |

## State Files

All in `~/.config/claude/`:

| File | Purpose | Writer(s) |
|------|---------|-----------|
| `sounds.conf` | Configuration (mode, frequency) | User / `/jam` skill |
| `jam-streak.json` | Streak tracking | Stop, PostToolUse (reset) |
| `jam-stats.json` | Session basketball stats | PostToolUse, Notification, SessionStart (reset), SessionEnd (reset) |
| `jam-error-state.json` | Cross-hook error flag | PostToolUse → Stop |
| `jam-contextual-state.json` | Cross-hook contextual sound flag | PostToolUse → Stop |
| `jam-update.json` | Cached update check | UpdateChecker (background fork) |

## Cross-Platform Sound Playback

`hooks/lib/sound_player.rb` detects platform via `RbConfig::CONFIG['host_os']`:
- macOS: `afplay -v 0.3`
- Linux: `aplay` → `paplay` → `ffplay` (fallback chain)
- Windows: PowerShell `System.Media.SoundPlayer`

Methods: `play(file)`, `play_random(files)`, `play_weighted(weighted_hash)`. Non-blocking spawn with detached process. Sound errors are caught and logged but never block operations.

## Lib Modules Reference

| Module | File | Purpose |
|--------|------|---------|
| `SoundPlayer` | `hooks/lib/sound_player.rb` | Cross-platform audio playback |
| `StreakTracker` | `hooks/lib/streak_tracker.rb` | Persistent streak state |
| `ErrorDetector` | `hooks/lib/error_detector.rb` | Categorize errors from tool responses |
| `ErrorSoundMapper` | `hooks/lib/error_sound_mapper.rb` | Map error categories to sounds |
| `ErrorState` | `hooks/lib/error_state.rb` | Cross-hook error coordination |
| `ContextualCommentary` | `hooks/lib/contextual_commentary.rb` | Detect special tool events for sounds |
| `ContextualSoundState` | `hooks/lib/contextual_sound_state.rb` | Cross-hook contextual sound coordination |
| `SessionStats` | `hooks/lib/session_stats.rb` | Basketball stat tracking |
| `NbaFacts` | `hooks/lib/nba_facts.rb` | 175+ curated NBA/arcade facts |
| `FactPresenter` | `hooks/lib/fact_presenter.rb` | TikTok-style fact formatting |
| `AsciiBanner` | `hooks/lib/ascii_banner.rb` | Fire gradient logo + version + fact display |
| `BoxScore` | `hooks/lib/box_score.rb` | Post-game stats with rating tiers |
| `FireColors` | `hooks/lib/fire_colors.rb` | Auto-detecting fire gradient palette |
| `UpdateChecker` | `hooks/lib/update_checker.rb` | Background update detection |
| `JamConfig` | `lib/jam_config.rb` | Config file reader |

## Plugin Registration (3-Layer System)

The installer (`install.sh`) registers across three layers — all must be in sync:
1. **Marketplace:** `~/.claude/plugins/known_marketplaces.json`
2. **Install registry:** `~/.claude/plugins/installed_plugins.json` (v2 format)
3. **Settings:** `~/.claude/settings.json` → `enabledPlugins` array

The PostToolUse hook is also manually registered in `settings.json` because Claude Code ignores it from `hooks.json` (known platform limitation).

Files are copied to both cache (`~/.claude/plugins/cache/jam-claude/jam-claude/<version>/`) and marketplace (`~/.claude/plugins/marketplaces/jam-claude/jam-claude-plugin/`).

## Key Conventions

- **Ruby only** — no gems, no Gemfile. Uses only Ruby stdlib (`json`, `rbconfig`, `shellwords`, `fileutils`)
- **Vendored dependency:** `vendor/claude_hooks/` is a fork of gabriel-dehan/claude_hooks — do not install via gem
- **Handler pattern:** Sound weights defined as frozen hash constants at class level; `call` method contains all business logic
- **Graceful degradation:** If sounds are disabled or audio player missing, hooks return success silently
- **ANSI colors:** Use `-e` flag with `echo` for color codes; use bright variants (e.g., `\033[92m`) for terminal compatibility
- **TTY output:** Banner and box score write directly to `/dev/tty` to bypass stdout JSON and stderr limitations
- **Atomic writes:** All state files use temp-file-then-rename (PID-specific temp files for error/contextual state)

## Commands

```bash
# Install plugin (cross-platform)
./install.sh

# Uninstall cleanly (removes all 3 registration layers + config + state files)
./uninstall.sh

# Toggle mode via skill
/jam-claude:jam on|off|frequent|normal|low
```

## Testing

Custom lightweight test framework (`test/test_helper.rb`) with assertions, stubs, sandbox isolation, and a test runner. 252 tests across 22 files covering 100% of modules (15/15) and handlers (5/5). All tests use temp directories — zero risk to real `~/.config/claude/` files.

```bash
ruby test/run_tests.rb              # all tests (252)
ruby test/run_tests.rb unit         # pure logic tests (97)
ruby test/run_tests.rb integration  # sandbox I/O tests (97)
ruby test/run_tests.rb handler      # full handler flow tests (58)
ruby test/run_tests.rb streak       # pattern match on filename
```

| Directory | Files | Coverage |
|-----------|-------|----------|
| `test/unit/` | 7 | StatsCalculator, ErrorDetector, ErrorSoundMapper, ContextualCommentary, NbaFacts, FactPresenter, FireColors |
| `test/integration/` | 9 | ErrorState, ContextualSoundState, StreakTracker, SessionStats, JamConfig, SoundPlayer, BoxScore, AsciiBanner, UpdateChecker |
| `test/handlers/` | 5 | PostToolUse, Stop, SessionStart, Notification, SessionEnd |

## Versioning

Single source of truth: `.claude-plugin/plugin.json` holds the version. Use the bump script or skill:

```bash
# Via skill (prompts for type + entry)
/jam-claude:version-bump

# Via script
ruby scripts/version-bump.rb patch "Fixed X"
ruby scripts/version-bump.rb minor "Added Y"
ruby scripts/version-bump.rb major "Breaking change Z"
ruby scripts/version-bump.rb patch "Test" --dry-run
```

The script updates `.claude-plugin/plugin.json` and `CHANGELOG.md`. `install.sh` reads the version dynamically from `plugin.json` — no manual sync needed.

When ready to send a PR, always increase minor version and create a changelog entry.

---

## Git Workflow

### MANDATORY: Worktree-First Development

**BLOCKING REQUIREMENT:** Before making ANY code changes (planning, editing, creating files), you MUST:

1. **Check current branch:** Run `git branch --show-current`
2. **If on main:** IMMEDIATELY create a worktree with a descriptive branch name:
   ```bash
   git worktree add -b feature/descriptive-name ../jam-claude-feature-descriptive-name
   cd ../jam-claude-feature-descriptive-name
   ```
3. **Never ask permission** - just create the worktree and announce it
4. **All subsequent work** happens in the worktree - never switch back to main

**Triggers for worktree creation:**
- Entering plan mode for a feature/fix/enhancement
- User asks to "fix", "add", "update", "refactor", or "change" anything
- ANY task that will modify files (excluding pure research/reading)

**Branch naming convention:**
- `feature/` - new functionality
- `fix/` - bug fixes
- `refactor/` - code restructuring
- `docs/` - documentation only changes

### Pull Request Workflow

When the feature is complete and approved:

1. **Sync with main:** `git fetch origin main && git rebase origin/main`
2. **Push to remote:** `git push -u origin <branch-name>`
3. **Create PR:** Use `gh pr create` (scripted, not interactive):
   ```bash
   gh pr create --title "Title" --body "$(cat <<'EOF'
   ## Summary
   - Change 1
   - Change 2

   ## Testing
   - Verified X
   - Tested Y
   EOF
   )"
   ```
4. **Never push directly to main** - all changes go through PRs

### Worktree Cleanup

After PR is merged:
```bash
cd /Users/andreasgiannopoulos/.claude/plugins/jam-claude  # back to main
git worktree remove ../jam-claude-feature-descriptive-name
git branch -d feature/descriptive-name  # delete local branch
```

## Quality Standards

### Post-Implementation Checks

After code is written, before marking work as done:
1. **Review for simplicity** — is there unnecessary complexity?
2. **Review for security** — any injection vectors, unsafe inputs, credential exposure?
3. **Review for performance** — unbounded loops, N+1 queries, missing error handling?

Use parallel subagents for these reviews when the changeset is non-trivial.

### Feature Completion Protocol

After feature development is complete, PROVE that it works before proceeding:
- **Demonstrate end-to-end:** Show the feature working with actual execution, not just "the code looks right"
- **Evidence required:** Logs, screenshots, test output, command output — concrete proof the feature behaves as intended
- **No theoretical completions:** "This should work" is not sufficient — show that it does work
- **Block until proven:** Do not move to next steps (PR, documentation, etc.) until working proof is provided

This applies to all features: new hooks, installer changes, sound playback, streak tracking, configuration handling.

### Documentation

- After any code change, evaluate whether documentation needs updating (CLAUDE.md, README, inline comments, install scripts).
- Use parallel subagents to check documentation alongside code reviews when suitable.
