# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/session_stats'
require_relative '../lib/box_score'
require_relative '../../lib/jam_config'

# JAM Claude SessionEnd Handler
#
# Plays game over sounds when session ends:
# - "exit": "Wins The Game"
# - "clear": "At the Buzzer"
# - "prompt_input_exit": "Overtime" (quit at the prompt — we went to overtime)

class JamClaudeSessionEndHandler < ClaudeHooks::SessionEnd
  END_SOUNDS = {
    'exit' => 'Wins The Game.wav',
    'clear' => 'At the Buzzer.wav',
    'prompt_input_exit' => 'Overtime.wav'
  }.freeze

  DEFAULT_SOUND = 'Wins The Game.wav'

  def call
    end_reason = reason || 'unknown'
    log "JAM Claude: Session ending (#{end_reason})"

    sound = END_SOUNDS[end_reason] || DEFAULT_SOUND
    success = SoundPlayer.play(sound, self)

    log success ? "JAM Claude: Played #{sound}" : "JAM Claude: Failed to play sound",
        level: success ? :info : :warn

    display_box_score

    allow_continue!
    suppress_output!
    output_data
  end

  private

  def display_box_score
    return unless JamConfig.jam?

    stats = SessionStats.stats
    return if stats['turns'] <= 0

    BoxScore.display(stats, stats['peak_streak'], stats['was_on_fire'])
    SessionStats.reset
  rescue StandardError => e
    log "JAM Claude: Box score display failed: #{e.message}", level: :warn
  end
end
