# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

# SessionStats - Track coding session statistics as basketball stats
#
# State file: ~/.config/claude/jam-stats.json
# Tracks: points, assists, rebounds, dunks, steals, blocks, peak_streak, was_on_fire
#
# Usage:
#   SessionStats.record(tool_name)
#   SessionStats.increment_blocks
#   SessionStats.update_peak_streak(streak)
#   SessionStats.stats
#   SessionStats.reset

class SessionStats
  STATE_PATH = File.expand_path('~/.config/claude/jam-stats.json')

  # Map tool names to stat categories
  TOOL_CATEGORIES = {
    'Edit' => :assists,
    'Read' => :rebounds,
    'Grep' => :rebounds,
    'Glob' => :rebounds,
    'Write' => :dunks,
    'Bash' => :steals
  }.freeze

  class << self
    # Record a tool use - increments points and appropriate stat category
    def record(tool_name)
      state = load_state
      state['points'] += 1

      # Increment category-specific stat
      category = TOOL_CATEGORIES[tool_name]
      state[category.to_s] += 1 if category

      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Increment blocks (permission prompts)
    def increment_blocks
      state = load_state
      state['blocks'] += 1
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
        'points' => 0,
        'assists' => 0,
        'rebounds' => 0,
        'dunks' => 0,
        'steals' => 0,
        'blocks' => 0,
        'peak_streak' => 0,
        'was_on_fire' => false,
        'last_updated' => Time.now.iso8601
      }
    end
  end
end
