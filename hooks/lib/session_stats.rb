# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

# SessionStats - Track raw tool usage during a coding session
#
# State file: ~/.config/claude/jam-stats.json
# Tracks: total_tools, edits, reads, writes, bashes, permissions, errors,
#         turns, error_turns, peak_streak, was_on_fire
#
# Usage:
#   SessionStats.record(tool_name)
#   SessionStats.increment_permissions
#   SessionStats.increment_errors
#   SessionStats.increment_turns(error_occurred:)
#   SessionStats.update_peak_streak(streak)
#   SessionStats.stats
#   SessionStats.reset

class SessionStats
  STATE_PATH = File.expand_path('~/.config/claude/jam-stats.json')

  # Map tool names to stat categories
  TOOL_CATEGORIES = {
    'Edit' => :edits,
    'Read' => :reads,
    'Grep' => :reads,
    'Glob' => :reads,
    'Write' => :writes,
    'Bash' => :bashes
  }.freeze

  class << self
    # Record a tool use - increments total_tools and appropriate stat category
    def record(tool_name)
      state = load_state
      state['total_tools'] += 1

      # Increment category-specific stat
      category = TOOL_CATEGORIES[tool_name]
      state[category.to_s] += 1 if category

      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Increment permissions (permission prompts)
    def increment_permissions
      state = load_state
      state['permissions'] += 1
      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Increment errors (detected failures)
    def increment_errors
      state = load_state
      state['errors'] += 1
      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Increment turns — each Claude response is a turn
    def increment_turns(error_occurred:)
      state = load_state
      state['turns'] += 1
      state['error_turns'] += 1 if error_occurred
      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Update peak streak and on_fire status
    def update_peak_streak(current_streak)
      state = load_state
      state['peak_streak'] = [state['peak_streak'], current_streak].max
      state['was_on_fire'] = true if current_streak >= 3
      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Get current stats
    def stats
      load_state
    end

    # Reset all stats to zero
    def reset
      save_state(default_state)
    end

    private

    # Load state from JSON file
    def load_state
      return default_state unless File.exist?(STATE_PATH)

      JSON.parse(File.read(STATE_PATH))
    rescue JSON::ParserError, StandardError
      # Corrupt file, reset to defaults
      default_state
    end

    # Save state to JSON file (atomic write)
    def save_state(state)
      FileUtils.mkdir_p(File.dirname(STATE_PATH))

      # Atomic write: write to temp, then rename
      temp_path = "#{STATE_PATH}.tmp"
      File.write(temp_path, JSON.pretty_generate(state))
      File.rename(temp_path, STATE_PATH)
    rescue StandardError => e
      warn("[SessionStats] Failed to save state: #{e.message}")
    end

    # Default state structure
    def default_state
      {
        'total_tools' => 0,
        'edits' => 0,
        'reads' => 0,
        'writes' => 0,
        'bashes' => 0,
        'permissions' => 0,
        'errors' => 0,
        'turns' => 0,
        'error_turns' => 0,
        'peak_streak' => 0,
        'was_on_fire' => false,
        'last_updated' => Time.now.iso8601
      }
    end
  end
end
