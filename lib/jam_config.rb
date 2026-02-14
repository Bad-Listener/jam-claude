# frozen_string_literal: true

# JamConfig Module
#
# Reads sound mode configuration for JAM Claude plugin.
# Config file: ~/.config/claude/sounds.conf
# Format: SOUND_MODE=jam|off
#
# Default: off (sounds disabled unless explicitly enabled)

module JamConfig
  CONFIG_PATH = File.expand_path('~/.config/claude/sounds.conf')
  VALID_MODES = %w[off jam].freeze
  DEFAULT_MODE = 'off'

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

    # Check if JAM mode is enabled
    def jam?
      mode == 'jam'
    end

    # Check if sounds are disabled
    def off?
      mode == 'off'
    end
  end
end
