# frozen_string_literal: true

require 'json'
require 'fileutils'

module ErrorState
  STATE_FILE = File.expand_path('~/.config/claude/jam-error-state.json').freeze

  # Default state structure
  DEFAULT_STATE = { 'error_occurred' => false }.freeze

  # Mark that an error occurred in the current turn
  def self.mark_error!
    write_state({ 'error_occurred' => true })
  end

  # Check if error occurred and clear the state
  # @return [Boolean] True if error occurred
  def self.error_and_clear?
    state = read_state
    error_occurred = state['error_occurred']

    # Clear state for next turn
    clear!

    error_occurred
  end

  # Clear error state
  def self.clear!
    write_state(DEFAULT_STATE)
  end

  # Read current error state
  # @return [Hash] State hash
  def self.read_state
    return DEFAULT_STATE unless File.exist?(STATE_FILE)

    JSON.parse(File.read(STATE_FILE))
  rescue JSON::ParserError, Errno::ENOENT
    # Corrupt or missing file - return default
    DEFAULT_STATE.dup
  end

  # Write state to file atomically
  # @param state [Hash] State to write
  def self.write_state(state)
    # Ensure config directory exists
    FileUtils.mkdir_p(File.dirname(STATE_FILE))

    # Atomic write using temp file + rename
    temp_file = "#{STATE_FILE}.tmp.#{Process.pid}"
    File.write(temp_file, JSON.pretty_generate(state))
    File.rename(temp_file, STATE_FILE)
  rescue StandardError => e
    # Log error but don't crash
    warn "ErrorState: Failed to write state: #{e.message}"
    # Clean up temp file if it exists
    File.delete(temp_file) if File.exist?(temp_file)
  end
end
