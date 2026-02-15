# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JAM Claude is a Claude Code plugin that plays NBA Jam (1993 arcade) sound effects and commentary during coding sessions. It uses Claude Code's hook system to trigger sounds on session events, tracks streaks of successful operations, and injects NBA Jam commentary into responses.

## Architecture

### Event-Driven Hook System

Four hooks registered in `hooks/hooks.json`, each following the pattern:

```
hooks/entrypoints/<event>.rb  →  hooks/handlers/<event>_handler.rb  →  hooks/lib/*.rb
```

- **Entrypoints** parse stdin JSON and delegate to handlers
- **Handlers** extend `ClaudeHooks::*` base classes from vendored DSL (`vendor/claude_hooks/`)
- **Lib modules** provide cross-cutting concerns (sound playback, streak tracking, ASCII art)

| Hook | Trigger | Behavior |
|------|---------|----------|
| `session_start` | Session opens | ASCII banner + welcome sound + inject commentary context |
| `stop` | Claude finishes responding | Increment streak + play weighted success sound |
| `notification` | Permission/idle/elicitation | Play referee sound (whistle/buzz/horn) |
| `session_end` | Session closes | Play game-over sound based on exit reason |

### Streak Progression

Streak state persists in `~/.config/claude/jam-streak.json` using atomic temp-file-then-rename writes.

- Streak 0-1: Base sound pool (11 sounds, weighted)
- Streak 2: "Heating Up" guaranteed
- Streak 3-4: Base pool + "He's on Fire" (15%)
- Streak 5+: Base pool + "He's on Fire" (30%)

### Configuration

- **Config file:** `~/.config/claude/sounds.conf` → `SOUND_MODE=jam|off`
- **Env override:** `CLAUDE_DISABLE_SOUNDS=1` takes precedence
- **Config reader:** `lib/jam_config.rb` provides `JamConfig.jam?` / `JamConfig.off?`

### Cross-Platform Sound Playback

`hooks/lib/sound_player.rb` detects platform via `RbConfig::CONFIG['host_os']`:
- macOS: `afplay -v 0.3`
- Linux: `aplay` → `paplay` → `ffplay` (fallback chain)
- Windows: PowerShell `System.Media.SoundPlayer`

Sound errors are caught and logged but never block operations.

## Key Conventions

- **Ruby only** — no gems, no Gemfile. Uses only Ruby stdlib (`json`, `rbconfig`, `shellwords`, `fileutils`)
- **Vendored dependency:** `vendor/claude_hooks/` is a fork of gabriel-dehan/claude_hooks — do not install via gem
- **Handler pattern:** Sound weights defined as frozen hash constants at class level; `call` method contains all business logic
- **Graceful degradation:** If sounds are disabled or audio player missing, hooks return success silently
- **ANSI colors:** Use `-e` flag with `echo` for color codes; use bright variants (e.g., `\033[92m`) for terminal compatibility

## Plugin Registration (3-Layer System)

The installer (`install.sh`) registers across three layers — all must be in sync:
1. **Marketplace:** `~/.claude/marketplace/known_marketplaces.json`
2. **Install registry:** `~/.claude/marketplace/installed_plugins.json` (v2 format)
3. **Settings:** `~/.claude/settings.json` → `enabledPlugins` array

## Commands

```bash
# Install plugin (cross-platform)
./install.sh

# Uninstall cleanly (removes all 3 registration layers + config + cache)
./uninstall.sh

# Toggle mode via skill
/jam-claude:jam on|off|demo
```

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

5. When we are ready to send a PR, always increase minor version and create a changelog entry. 

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

## Post-Implementation Checks

After code is written, before marking work as done:
1. **Review for simplicity** — is there unnecessary complexity?
2. **Review for security** — any injection vectors, unsafe inputs, credential exposure?
3. **Review for performance** — unbounded loops, N+1 queries, missing error handling?

Use parallel subagents for these reviews when the changeset is non-trivial.

## Feature Completion Protocol

After feature development is complete, PROVE that it works before proceeding:
- **Demonstrate end-to-end:** Show the feature working with actual execution, not just "the code looks right"
- **Evidence required:** Logs, screenshots, test output, command output — concrete proof the feature behaves as intended
- **No theoretical completions:** "This should work" is not sufficient — show that it does work
- **Block until proven:** Do not move to next steps (PR, documentation, etc.) until working proof is provided

This applies to all features: new hooks, installer changes, sound playback, streak tracking, configuration handling.

## Versioning

Single source of truth: `plugin.json` holds the version. Use the bump script or skill:

```bash
# Via skill (prompts for type + entry)
/jam-claude:version-bump

# Via script
ruby scripts/version-bump.rb patch "Fixed X"
ruby scripts/version-bump.rb minor "Added Y"
ruby scripts/version-bump.rb major "Breaking change Z"
ruby scripts/version-bump.rb patch "Test" --dry-run
```

The script updates `plugin.json` and `CHANGELOG.md`. `install.sh` reads the version dynamically from `plugin.json` — no manual sync needed.

## Documentation

- After any code change, evaluate whether documentation needs updating (CLAUDE.md, README, inline comments, install scripts).
- Use parallel subagents to check documentation alongside code reviews when suitable.
