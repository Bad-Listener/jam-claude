# frozen_string_literal: true

# JamConfig Module
#
# Reads sound mode and frequency configuration for JAM Claude plugin.
# Config file: ~/.config/claude/sounds.conf
# Format:
#   SOUND_MODE=jam|off
#   SOUND_FREQUENCY=frequent|normal|low
#
# Default: off (sounds disabled unless explicitly enabled)
# Default frequency: normal

module JamConfig
  CONFIG_PATH = File.expand_path('~/.config/claude/sounds.conf')
  VALID_MODES = %w[off jam].freeze
  DEFAULT_MODE = 'off'
  VALID_FREQUENCIES = %w[frequent normal low].freeze
  DEFAULT_FREQUENCY = 'normal'

  class << self
    # Read current sound mode from config file
    # @return [String] one of: off, jam
    def mode
      return DEFAULT_MODE unless File.exist?(CONFIG_PATH)

      content = File.read(CONFIG_PATH)
      match = content.match(/^SOUND_MODE=(\w+)/i)
      parsed_mode = match ? match[1].downcase : DEFAULT_MODE
      VALID_MODES.include?(parsed_mode) ? parsed_mode : DEFAULT_MODE
    rescue StandardError
      DEFAULT_MODE
    end

    # Read current sound frequency from config file
    # @return [String] one of: frequent, normal, low
    def frequency
      return DEFAULT_FREQUENCY unless File.exist?(CONFIG_PATH)

      content = File.read(CONFIG_PATH)
      match = content.match(/^SOUND_FREQUENCY=(\w+)/i)
      parsed = match ? match[1].downcase : DEFAULT_FREQUENCY
      VALID_FREQUENCIES.include?(parsed) ? parsed : DEFAULT_FREQUENCY
    rescue StandardError
      DEFAULT_FREQUENCY
    end

    # Check if JAM mode is enabled
    def jam?
      mode == 'jam'
    end

    # Check if sounds are disabled
    def off?
      mode == 'off'
    end

    # Check if frequent mode (all sounds + contextual commentary)
    def frequent?
      jam? && frequency == 'frequent'
    end

    # Check if normal mode (default density)
    def normal?
      jam? && frequency == 'normal'
    end

    # Check if low mode (minimal sounds, milestones only)
    def low?
      jam? && frequency == 'low'
    end
  end
end
