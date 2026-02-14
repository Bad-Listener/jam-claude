# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/streak_tracker'

# JAM Claude Stop Handler
#
# Plays success sounds when Claude finishes responding.
# Uses weighted random based on current streak.
#
# Weights:
# - Normal (0-2 streak): "It's Good" (40%), "From Downtown" (25%), "Monster Jam" (20%)
# - On Fire (3+ streak): "He's on Fire" (15%)
# - Super Hot (5+ streak): "He's on Fire" (30%)

class JamClaudeStopHandler < ClaudeHooks::Stop
  # Base sounds (always available)
  BASE_SOUNDS = {
    "It's Good.wav" => 0.40,
    'From Downtown.wav' => 0.25,
    'Monster Jam.wav' => 0.20,
    'Kaboom.wav' => 0.15
  }.freeze

  # Fire sound (unlocked at 3+ streak)
  FIRE_SOUND = "He's on Fire.wav"

  def call
    log 'JAM Claude: Response completed'

    # Increment streak (assuming success)
    current_streak = StreakTracker.increment
    log "JAM Claude: Current streak: #{current_streak}"

    # Determine sound weights based on streak
    sounds = calculate_sound_weights(current_streak)

    # Play weighted random sound
    success = SoundPlayer.play_weighted(sounds, self)
    log success ? 'JAM Claude: Played completion sound' : 'JAM Claude: Failed to play sound',
        level: success ? :info : :warn

    allow_continue!
    suppress_output!
    output_data
  end

  private

  def calculate_sound_weights(streak)
    weights = BASE_SOUNDS.dup

    # Unlock "He's on Fire" at 3+ streak
    if streak >= 3 && streak < 5
      # Reduce base weights slightly, add fire
      weights = weights.transform_values { |w| w * 0.85 }
      weights[FIRE_SOUND] = 0.15
    elsif streak >= 5
      # Super hot: higher fire chance
      weights = weights.transform_values { |w| w * 0.70 }
      weights[FIRE_SOUND] = 0.30
    end

    weights
  end
end
