# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/streak_tracker'
require_relative '../lib/session_stats'
require_relative '../lib/error_state'
require_relative '../lib/contextual_sound_state'
require_relative '../../lib/jam_config'

# JAM Claude Stop Handler
#
# Plays success sounds when Claude finishes responding.
# Uses weighted random based on current streak.
#
# Streak progression (classic NBA Jam sequence):
# - Normal (0-1 streak): Weighted random from base pool
# - Heating Up (2 streak): "Heating Up" guaranteed
# - On Fire (3-4 streak): Base pool + "He's on Fire" (15%)
# - Super Hot (5+ streak): Base pool + "He's on Fire" (30%)
#
# Frequency modes:
# - frequent/normal: Full sound pool with streak progression
# - low: Silent for streak 0-1, Heating Up at 2, He's on Fire at 3+

class JamClaudeStopHandler < ClaudeHooks::Stop
  # Base sounds (always available)
  BASE_SOUNDS = {
    "It's Good.wav" => 0.20,
    'From Downtown.wav' => 0.15,
    'Monster Jam.wav' => 0.12,
    'Kaboom.wav' => 0.10,
    'Scores.wav' => 0.10,
    'Slams It.wav' => 0.10,
    'Razzle Dazzle.wav' => 0.08,
    'Show Time.wav' => 0.05,
    'Hooks It In.wav' => 0.04,
    'Woah.wav' => 0.03,
    'Yes.wav' => 0.03
  }.freeze

  # Streak sounds
  HEATING_UP_SOUND = 'Heating Up.wav'
  FIRE_SOUND = "He's on Fire.wav"

  def call
    log 'JAM Claude: Response completed'

    # Check if error occurred in this turn - skip success sound if so
    if ErrorState.error_and_clear?
      log 'JAM Claude: Skipping success sound due to error in this turn'
      allow_continue!
      suppress_output!
      return output_data
    end

    # Increment streak (only if no error)
    current_streak = StreakTracker.increment
    SessionStats.update_peak_streak(current_streak) if JamConfig.jam?
    log "JAM Claude: Current streak: #{current_streak}"

    # Skip generic success sound if contextual sound already played this turn
    if ContextualSoundState.played_and_clear?
      log 'JAM Claude: Skipping success sound — contextual sound already played'
      allow_continue!
      suppress_output!
      return output_data
    end

    # In low mode, only play on streak milestones
    unless should_play_sound?(current_streak)
      log 'JAM Claude: Low mode — skipping sound (no milestone)'
      allow_continue!
      suppress_output!
      return output_data
    end

    # Determine sound weights based on streak and frequency
    sounds = JamConfig.low? ? low_mode_sound(current_streak) : calculate_sound_weights(current_streak)

    # Play weighted random sound
    success = SoundPlayer.play_weighted(sounds, self)
    log success ? 'JAM Claude: Played completion sound' : 'JAM Claude: Failed to play sound',
        level: success ? :info : :warn

    allow_continue!
    suppress_output!
    output_data
  end

  private

  # In low mode, only play sounds at streak milestones (2+)
  def should_play_sound?(streak)
    return true unless JamConfig.low?

    streak >= 2
  end

  # Simplified sound pool for low mode
  def low_mode_sound(streak)
    if streak == 2
      { HEATING_UP_SOUND => 1.0 }
    else
      { FIRE_SOUND => 1.0 }
    end
  end

  def calculate_sound_weights(streak)
    # Streak 2: guaranteed "Heating Up" (classic Jam progression)
    if streak == 2
      return { HEATING_UP_SOUND => 1.0 }
    end

    weights = BASE_SOUNDS.dup

    # Unlock "He's on Fire" at 3+ streak
    if streak >= 3 && streak < 5
      weights = weights.transform_values { |w| w * 0.85 }
      weights[FIRE_SOUND] = 0.15
    elsif streak >= 5
      weights = weights.transform_values { |w| w * 0.70 }
      weights[FIRE_SOUND] = 0.30
    end

    weights
  end
end
