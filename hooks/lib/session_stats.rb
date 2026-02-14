# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

# SessionStats - Track coding actions as basketball stats per session
#
# State file: ~/.config/claude/jam-stats.json
# Tracks: points, assists, rebounds, dunks, steals, blocks, peak_streak, was_on_fire
#
# Stat mapping:
#   PTS  = All successful tool calls
#   AST  = Edit calls
#   REB  = Read/Grep/Glob calls
#   DNK  = Write calls (new files)
#   STL  = Bash commands
#   BLK  = Permission prompts
#   STREAK = Session peak streak
#   ON FIRE = Hit 3+ streak

class SessionStats
  STATE_PATH = File.expand_path('~/.config/claude/jam-stats.json')

  TOOL_CATEGORIES = {
    'Edit' => 'assists',
    'Read' => 'rebounds',
    'Grep' => 'rebounds',
    'Glob' => 'rebounds',
    'Write' => 'dunks',
    'Bash' => 'steals'
  }.freeze

  class << self
    # Record a tool call, incrementing points and the appropriate category
    def record(tool_name)
      state = load_state
      state['points'] += 1

      category = TOOL_CATEGORIES[tool_name]
      state[category] += 1 if category

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
    def update_peak_streak(streak)
      state = load_state
      state['peak_streak'] = [state['peak_streak'], streak].max
      state['was_on_fire'] = true if streak >= 3
      state['last_updated'] = Time.now.iso8601
      save_state(state)
    end

    # Get current stats hash
    def stats
      load_state
    end

    # Reset all stats to zeros
    def reset
      save_state(default_state)
    end

    private

    def load_state
      return default_state unless File.exist?(STATE_PATH)

      JSON.parse(File.read(STATE_PATH))
    rescue JSON::ParserError, StandardError
      default_state
    end

    def save_state(state)
      FileUtils.mkdir_p(File.dirname(STATE_PATH))

      temp_path = "#{STATE_PATH}.tmp"
      File.write(temp_path, JSON.pretty_generate(state))
      File.rename(temp_path, STATE_PATH)
    rescue StandardError => e
      warn("[SessionStats] Failed to save state: #{e.message}")
    end

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
