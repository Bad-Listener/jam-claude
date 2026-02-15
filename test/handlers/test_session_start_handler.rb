# frozen_string_literal: true

require_relative '../test_helper'

vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)
require 'claude_hooks'

require_relative '../../hooks/handlers/session_start_handler'

class TestSessionStartHandler < JamTest::TestCase
  def setup
    super
    create_sandbox

    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')
    sandbox_const(UpdateChecker, :STATE_PATH, 'jam-update.json')

    # Stub sound playback
    @play_weighted_stub = stub_method(SoundPlayer, :play_weighted) { true }

    # Stub display methods to avoid TTY writes
    @display_stub = stub_method(AsciiBanner, :display) { nil }
    @notice_stub = stub_method(AsciiBanner, :display_update_notice) { nil }

    # Stub update checker to avoid forking
    stub_method(UpdateChecker, :check_in_background!) { nil }
  end

  def test_resets_stats
    # Pre-populate stats
    SessionStats.reset
    SessionStats.record('Edit')
    assert_equal 1, SessionStats.stats['total_tools']

    handler = build_handler
    handler.call

    assert_equal 0, SessionStats.stats['total_tools']
  end

  def test_displays_banner
    handler = build_handler
    handler.call

    assert @display_stub.called?, 'Should display ASCII banner'
  end

  def test_plays_startup_sound
    handler = build_handler
    handler.call

    assert @play_weighted_stub.called?, 'Should play startup sound'
  end

  def test_startup_sound_weights
    handler = build_handler
    handler.call

    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?('28 - Welcome to NBA Jam.wav')
    assert sounds.key?('Hello.wav')
    assert sounds.key?("Tonight's Matchup.wav")
  end

  def test_injects_commentary_context
    handler = build_handler
    result = handler.call

    # Should have hookSpecificOutput with additionalContext
    hook_output = result['hookSpecificOutput']
    assert_not_nil hook_output, 'Should inject hookSpecificOutput'
    assert_not_nil hook_output['additionalContext']
    assert_includes hook_output['additionalContext'], 'JAM Claude Mode Active'
  end

  def test_allows_continue
    handler = build_handler
    result = handler.call

    assert_true result['continue']
  end

  def test_suppresses_output
    handler = build_handler
    result = handler.call

    assert_true result['suppressOutput']
  end

  def test_checks_update_notice
    handler = build_handler
    handler.call

    assert @notice_stub.called?, 'Should check for update notice'
  end

  private

  def build_handler(source = 'startup')
    JamClaudeSessionStartHandler.new({ 'source' => source })
  end
end
