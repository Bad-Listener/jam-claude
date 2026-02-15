# frozen_string_literal: true

require_relative '../test_helper'

# Load vendor claude_hooks
vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)
require 'claude_hooks'

require_relative '../../hooks/handlers/post_tool_use_handler'

class TestPostToolUseHandler < JamTest::TestCase
  def setup
    super
    create_sandbox

    # Sandbox all state files
    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
    sandbox_const(ErrorState, :STATE_FILE, 'jam-error-state.json')
    sandbox_const(ContextualSoundState, :STATE_FILE, 'jam-contextual-state.json')
    sandbox_const(StreakTracker, :STATE_PATH, 'jam-streak.json')
    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')

    # Enable JAM mode by default
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n")

    # Stub SoundPlayer to avoid actual sound playback
    @play_stub = stub_method(SoundPlayer, :play) { true }
    @play_weighted_stub = stub_method(SoundPlayer, :play_weighted) { true }

    # Reset stats
    SessionStats.reset
  end

  # ── Error detection flow ───────────────────────────────────────────────
  def test_error_sets_error_state
    handler = build_handler(error_response('Permission denied'))
    handler.call

    assert_true ErrorState.read_state['error_occurred']
  end

  def test_error_resets_streak
    StreakTracker.increment
    StreakTracker.increment

    handler = build_handler(error_response('Permission denied'))
    handler.call

    assert_equal 0, StreakTracker.current_streak
  end

  def test_error_increments_errors
    handler = build_handler(error_response('Permission denied'))
    handler.call

    assert_equal 1, SessionStats.stats['errors']
  end

  def test_error_plays_sound
    handler = build_handler(error_response('Permission denied'))
    handler.call

    assert @play_stub.called?, 'Expected error sound to play'
  end

  # ── Success flow ────────────────────────────────────────────────────────
  def test_success_does_not_set_error_state
    handler = build_handler(success_response)
    handler.call

    assert_false ErrorState.read_state['error_occurred']
  end

  def test_success_records_tool_usage
    handler = build_handler(success_response, 'Edit')
    handler.call

    assert_equal 1, SessionStats.stats['edits']
    assert_equal 1, SessionStats.stats['total_tools']
  end

  def test_success_records_bash_as_steals
    handler = build_handler(success_response, 'Bash')
    handler.call

    assert_equal 1, SessionStats.stats['bashes']
  end

  def test_success_records_read_as_rebounds
    handler = build_handler(success_response, 'Read')
    handler.call

    assert_equal 1, SessionStats.stats['reads']
  end

  # ── Frequent mode contextual sounds ────────────────────────────────────
  def test_frequent_mode_contextual_sound_detected
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=frequent\n")

    # Simulate large write
    input = {
      'tool_name' => 'Write',
      'tool_input' => { 'content' => "line\n" * 200 },
      'tool_response' => { 'content' => 'File written', 'is_error' => false }
    }

    handler = JamClaudePostToolUseHandler.new(input)
    handler.call

    assert_true ContextualSoundState.read_state['played']
  end

  def test_normal_mode_skips_contextual_sounds
    # Normal mode (not frequent)
    input = {
      'tool_name' => 'Write',
      'tool_input' => { 'content' => "line\n" * 200 },
      'tool_response' => { 'content' => 'File written', 'is_error' => false }
    }

    handler = JamClaudePostToolUseHandler.new(input)
    handler.call

    assert_false ContextualSoundState.read_state['played']
  end

  # ── Low mode error filtering ───────────────────────────────────────────
  def test_low_mode_skips_non_critical_error_sound
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")

    handler = build_handler(error_response('file not found'))
    handler.call

    # Error state should still be set regardless of sound
    assert_true ErrorState.read_state['error_occurred']
    # But non-critical error sound should NOT play
    assert_false @play_stub.called?, 'Low mode should skip non-critical error sounds'
  end

  def test_low_mode_plays_critical_error_sound
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")

    handler = build_handler(error_response('Permission denied'))
    handler.call

    assert @play_stub.called?, 'Low mode should play critical error sounds'
  end

  # ── Off mode ────────────────────────────────────────────────────────────
  def test_off_mode_skips_everything
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\n")

    handler = build_handler(success_response('Edit'))
    handler.call

    # No stats recorded when off
    assert_equal 0, SessionStats.stats['total_tools']
    assert_false @play_stub.called?
  end

  # ── Output data ─────────────────────────────────────────────────────────
  def test_allows_continue
    handler = build_handler(success_response)
    result = handler.call

    assert_true result['continue']
  end

  def test_suppresses_output
    handler = build_handler(success_response)
    result = handler.call

    assert_true result['suppressOutput']
  end

  private

  def build_handler(response, tool_name = 'Bash')
    input = {
      'tool_name' => tool_name,
      'tool_input' => {},
      'tool_response' => response
    }
    JamClaudePostToolUseHandler.new(input)
  end

  def error_response(content)
    { 'tool_name' => 'Bash', 'content' => content, 'is_error' => true }
  end

  def success_response(tool = 'Read')
    { 'tool_name' => tool, 'content' => 'OK', 'is_error' => false }
  end
end
