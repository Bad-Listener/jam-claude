---
description: Bump version and add changelog entry
argument-hint: "[patch|minor|major]"
allowed-tools: ["Bash", "Read"]
---

# Version Bump

Bump the JAM Claude version and add a changelog entry.

$ARGUMENTS

## Instructions

1. Determine the plugin root directory. This file lives at `<PLUGIN_ROOT>/commands/version-bump.md`.

2. If no argument was provided, ask the user:
   - Bump type: `patch` (bug fixes), `minor` (new features), `major` (breaking changes)
   - Changelog entry: one-line description of the change

3. If only a bump type was provided (e.g., `patch`), ask the user for the changelog entry.

4. Run a dry-run first to show what will change:
   ```bash
   ruby <PLUGIN_ROOT>/scripts/version-bump.rb <type> "<entry>" --dry-run
   ```

5. If dry-run looks correct, run the actual bump:
   ```bash
   ruby <PLUGIN_ROOT>/scripts/version-bump.rb <type> "<entry>"
   ```

6. Show the resulting diff:
   ```bash
   git -C <PLUGIN_ROOT> diff
   ```

7. Report the result:
   - "Version bumped: X.Y.Z -> A.B.C"
   - "CHANGELOG.md and plugin.json updated"
   - Remind: "Don't forget to include these changes in your commit"
