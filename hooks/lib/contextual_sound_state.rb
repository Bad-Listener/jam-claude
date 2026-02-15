# frozen_string_literal: true

require 'json'
require 'fileutils'

# ContextualSoundState Module
#
# Cross-hook state coordination for contextual sounds.
# PostToolUse marks when a contextual sound fires.
# Stop reads and auto-clears to skip generic success sound.
#
# Mirrors ErrorState pattern exactly.

module ContextualSoundState
  STATE_FILE = File.expand_path('~/.config/claude/jam-contextual-state.json').freeze

  DEFAULT_STATE = { 'played' => false }.freeze

  # Mark that a contextual sound played in the current turn
  def self.mark_played!
    write_state({ 'played' => true })
  end

  # Check if contextual sound played and clear the state
  # @return [Boolean] True if contextual sound played
  def self.played_and_clear?
    state = read_state
    played = state['played']

    clear!

    played
  end

  # Clear state
  def self.clear!
    write_state(DEFAULT_STATE)
  end

  # Read current state
  # @return [Hash] State hash
  def self.read_state
    return DEFAULT_STATE unless File.exist?(STATE_FILE)

    JSON.parse(File.read(STATE_FILE))
  rescue JSON::ParserError, Errno::ENOENT
    DEFAULT_STATE.dup
  end

  # Write state to file atomically
  # @param state [Hash] State to write
  def self.write_state(state)
    FileUtils.mkdir_p(File.dirname(STATE_FILE))

    temp_file = "#{STATE_FILE}.tmp.#{Process.pid}"
    File.write(temp_file, JSON.pretty_generate(state))
    File.rename(temp_file, STATE_FILE)
  rescue StandardError => e
    warn "ContextualSoundState: Failed to write state: #{e.message}"
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end
end
