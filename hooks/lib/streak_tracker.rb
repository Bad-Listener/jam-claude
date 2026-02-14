# frozen_string_literal: true

require 'json'
require 'fileutils'

# StreakTracker - Track consecutive successful Claude operations
#
# State file: ~/.config/claude/jam-streak.json
# Tracks: current_streak, best_streak, on_fire status
#
# Usage:
#   StreakTracker.increment
#   StreakTracker.reset
#   StreakTracker.on_fire?  # true if streak >= 3

class StreakTracker
  STATE_PATH = File.expand_path('~/.config/claude/jam-streak.json')

  class << self
    # Increment the current streak
    def increment
      state = load_state
      state['current_streak'] += 1
      state['best_streak'] = [state['best_streak'], state['current_streak']].max
      state['on_fire'] = state['current_streak'] >= 3
      state['last_updated'] = Time.now.iso8601
      save_state(state)
      state['current_streak']
    end

    # Reset streak to 0
    def reset
      state = load_state
      state['current_streak'] = 0
      state['on_fire'] = false
      state['last_updated'] = Time.now.iso8601
      save_state(state)
      0
    end

    # Get current streak count
    def current_streak
      load_state['current_streak']
    end

    # Check if on fire (3+ streak)
    def on_fire?
      load_state['on_fire']
    end

    # Get best streak ever
    def best_streak
      load_state['best_streak']
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
      warn("[StreakTracker] Failed to save state: #{e.message}")
    end

    # Default state structure
    def default_state
      {
        'current_streak' => 0,
        'best_streak' => 0,
        'last_updated' => Time.now.iso8601,
        'on_fire' => false
      }
    end
  end
end
