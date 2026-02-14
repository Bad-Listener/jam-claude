# frozen_string_literal: true

module ErrorSoundMapper
  # Sound mappings for each error category
  # Structure: { category: { 'sound_file.wav' => weight, ... } }

  SOUND_MAPPINGS = {
    permission_denied: {
      'Rejected.wav' => 1.0
    },
    file_not_found: {
      '54 - Off the rim.wav' => 1.0
    },
    exit_failure: {
      'Terrible Shot.wav' => 0.5,
      'No Good.wav' => 0.5
    },
    command_not_found: {
      'Wild Shot.wav' => 1.0
    },
    signal_termination: {
      '53 - Shove.wav' => 1.0
    },
    network_error: {
      'Intercepted.wav' => 1.0
    },
    syntax_error: {
      'Ugly Shot.wav' => 1.0
    },
    state_corruption: {
      'The Turnover.wav' => 1.0
    },
    generic_error: {
      'No Good.wav' => 0.7,
      'Wild Shot.wav' => 0.3
    }
  }.freeze

  # Get sound mapping for error category
  # @param category [Symbol] Error category from ErrorDetector
  # @return [Hash] Sound mapping hash { 'sound.wav' => weight }
  def self.sound_for_category(category)
    SOUND_MAPPINGS[category] || SOUND_MAPPINGS[:generic_error]
  end

  # Select a sound file based on weighted probabilities
  # @param category [Symbol] Error category
  # @return [String] Sound filename
  def self.select_sound(category)
    sound_map = sound_for_category(category)

    # If only one sound, return it directly
    return sound_map.keys.first if sound_map.size == 1

    # Weighted random selection
    total_weight = sound_map.values.sum
    random_value = rand * total_weight

    cumulative = 0.0
    sound_map.each do |sound, weight|
      cumulative += weight
      return sound if random_value <= cumulative
    end

    # Fallback (should never reach here)
    sound_map.keys.first
  end
end
