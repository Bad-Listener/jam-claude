# frozen_string_literal: true

require_relative '../../lib/jam_config'
require_relative '../lib/session_stats'
require_relative '../lib/error_detector'
require_relative '../lib/error_sound_mapper'
require_relative '../lib/error_state'
require_relative '../lib/sound_player'
require_relative '../lib/streak_tracker'

# JAM Claude PostToolUse Handler
#
# Records tool usage as basketball stats.
# Detects errors and plays error sounds, resets streaks.
# Never blocks — purely passive tracking and feedback.

class JamClaudePostToolUseHandler < ClaudeHooks::PostToolUse
  def call
    if JamConfig.jam?
      # Record tool usage
      SessionStats.record(tool_name) if tool_name

      # Detect errors in tool response
      error_category = ErrorDetector.detect(tool_response)

      if error_category
        handle_error(error_category)
      end
    end

    allow_continue!
    suppress_output!
    output_data
  end

  private

  def handle_error(error_category)
    log "JAM Claude: Error detected - #{error_category}"

    # Play error sound
    sound_file = ErrorSoundMapper.select_sound(error_category)
    SoundPlayer.play(sound_file)

    # Reset streak (errors are turnovers in NBA Jam)
    StreakTracker.reset
    log "JAM Claude: Streak reset due to error"

    # Mark error state for current turn
    ErrorState.mark_error!

    # Increment turnovers stat
    SessionStats.increment_turnovers
  end
end
