# frozen_string_literal: true

require_relative '../../lib/jam_config'
require_relative '../lib/session_stats'
require_relative '../lib/error_detector'
require_relative '../lib/error_sound_mapper'
require_relative '../lib/error_state'
require_relative '../lib/sound_player'
require_relative '../lib/streak_tracker'
require_relative '../lib/contextual_commentary'
require_relative '../lib/contextual_sound_state'

# JAM Claude PostToolUse Handler
#
# Records tool usage as basketball stats.
# Detects errors and plays error sounds, resets streaks.
# In frequent mode, plays contextual sounds for notable tool events.
# Never blocks — purely passive tracking and feedback.

class JamClaudePostToolUseHandler < ClaudeHooks::PostToolUse
  # Error categories that play sounds even in low mode
  CRITICAL_ERROR_CATEGORIES = %i[permission_denied signal_termination state_corruption].freeze

  def call
    if JamConfig.jam?
      # Record tool usage
      SessionStats.record(tool_name) if tool_name

      # Contextual sounds (frequent mode only, success events)
      if JamConfig.frequent?
        contextual_sound = ContextualCommentary.detect(tool_name, tool_input, tool_response)
        if contextual_sound
          log "JAM Claude: Contextual sound — #{contextual_sound}"
          SoundPlayer.play(contextual_sound)
          ContextualSoundState.mark_played!
        end
      end

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

    # In low mode, only play sounds for critical errors
    play_sound = !JamConfig.low? || CRITICAL_ERROR_CATEGORIES.include?(error_category)

    if play_sound
      sound_file = ErrorSoundMapper.select_sound(error_category)
      SoundPlayer.play(sound_file)
    else
      log 'JAM Claude: Low mode — skipping non-critical error sound'
    end

    # Always reset streak and track stats regardless of sound
    StreakTracker.reset
    log "JAM Claude: Streak reset due to error"

    ErrorState.mark_error!
    SessionStats.increment_errors
  end
end
