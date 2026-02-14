# frozen_string_literal: true

require 'rbconfig'
require_relative '../../lib/jam_config'

# SoundPlayer Module for JAM Claude
#
# Provides cross-platform sound playback for NBA Jam audio.
# Sound files bundled in vendor/sounds/ within the plugin.
#
# Usage:
#   SoundPlayer.play('He\'s on Fire.wav')
#   SoundPlayer.play_random(['It\'s Good.wav', 'From Downtown.wav'])
#
# Sound mode controlled by:
#   ~/.config/claude/sounds.conf (SOUND_MODE=jam to enable)
#
# Override via environment:
#   CLAUDE_DISABLE_SOUNDS=1

module SoundPlayer
  class << self
    # Play a single sound file
    # @param sound_file [String] the sound file name (relative to vendor/sounds/)
    # @param logger [Object] optional logger with #log method
    def play(sound_file, logger = nil)
      return true if sounds_disabled?

      sound_path = resolve_sound_path(sound_file)

      unless File.exist?(sound_path)
        log_error("Sound file not found: #{sound_path}", logger)
        return false
      end

      command = build_play_command(sound_path)
      execute_command(command, logger)
    end

    # Play a random sound from an array of sound files
    # @param sound_files [Array<String>] array of sound file names
    # @param logger [Object] optional logger with #log method
    def play_random(sound_files, logger = nil)
      return false if sound_files.empty?

      selected_sound = sound_files.sample
      log_debug("Selected random sound: #{selected_sound}", logger)
      play(selected_sound, logger)
    end

    # Play weighted random sound (for streak-based selection)
    # @param weighted_sounds [Hash] sound => weight (e.g., {'sound.wav' => 0.4})
    # @param logger [Object] optional logger
    def play_weighted(weighted_sounds, logger = nil)
      return false if weighted_sounds.empty?

      # Weighted random selection
      total_weight = weighted_sounds.values.sum
      random = rand * total_weight
      cumulative = 0

      weighted_sounds.each do |sound, weight|
        cumulative += weight
        if random <= cumulative
          log_debug("Selected weighted sound: #{sound} (weight: #{weight})", logger)
          return play(sound, logger)
        end
      end

      # Fallback to first
      play(weighted_sounds.keys.first, logger)
    end

    private

    # Check if sounds are disabled
    # JAM sounds only play when SOUND_MODE=jam, unless overridden by env vars
    def sounds_disabled?
      # Env vars take precedence
      return true if ENV['CLAUDE_DISABLE_SOUNDS']

      # Only play when sound mode is 'jam'
      !JamConfig.jam?
    end

    # Resolve sound file path using plugin-relative paths
    # @param sound_file [String] the sound file name
    # @return [String] absolute path to sound file
    def resolve_sound_path(sound_file)
      plugin_root = ENV['CLAUDE_PLUGIN_ROOT'] || File.expand_path('../../..', __dir__)
      File.join(plugin_root, 'vendor', 'sounds', sound_file)
    end

    # Build platform-specific sound play command
    # @param sound_path [String] absolute path to sound file
    # @return [String] shell command to play the sound
    def build_play_command(sound_path)
      escaped_path = shell_escape(sound_path)

      case detect_platform
      when :macos
        "afplay -v 0.3 #{escaped_path} 2>/dev/null &"
      when :windows
        "(New-Object Media.SoundPlayer '#{sound_path}').PlaySync() 2>$null &"
      when :linux
        "{ aplay -q #{escaped_path} || paplay #{escaped_path} || ffplay -nodisp -autoexit #{escaped_path}; } 2>/dev/null &"
      else
        "echo 'Unsupported platform for sound playback' >/dev/null &"
      end
    end

    # Execute the sound play command
    # @param command [String] shell command to execute
    # @param logger [Object] optional logger
    # @return [Boolean] true if command executed successfully
    def execute_command(command, logger)
      result = system(command)

      if result.nil?
        log_error("Failed to execute sound command: #{command}", logger)
        false
      else
        true
      end
    rescue StandardError => e
      log_error("Sound playback error: #{e.message}", logger)
      false
    end

    # Detect the current platform
    # @return [Symbol] :macos, :windows, :linux, or :unknown
    def detect_platform
      case RbConfig::CONFIG['host_os']
      when /darwin|mac os/
        :macos
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /linux/
        :linux
      else
        :unknown
      end
    end

    # Escape shell arguments to prevent injection
    # @param path [String] file path to escape
    # @return [String] shell-escaped path
    def shell_escape(path)
      "'#{path.gsub("'", "\\'")}'"
    end

    # Log error message
    def log_error(message, logger)
      if logger.respond_to?(:log)
        logger.log(message, level: :error)
      else
        warn("[SoundPlayer] #{message}")
      end
    end

    # Log debug message
    def log_debug(message, logger)
      if logger.respond_to?(:log)
        logger.log(message, level: :debug)
      elsif ENV['RUBY_CLAUDE_HOOKS_DEBUG']
        warn("[SoundPlayer] #{message}")
      end
    end
  end
end
