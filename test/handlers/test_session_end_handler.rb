# frozen_string_literal: true

require_relative '../test_helper'

vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)
require 'claude_hooks'

require_relative '../../hooks/handlers/session_end_handler'

class TestSessionEndHandler < JamTest::TestCase
  def setup
    super
    create_sandbox

    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')

    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n")

    @play_stub = stub_method(SoundPlayer, :play) { true }
    @box_score_stub = stub_method(BoxScore, :display) { nil }

    SessionStats.reset
  end

  def test_exit_plays_wins_the_game
    handler = build_handler('exit')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('Wins The Game.wav', handler)
  end

  def test_clear_plays_at_the_buzzer
    handler = build_handler('clear')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('At the Buzzer.wav', handler)
  end

  def test_prompt_exit_plays_overtime
    handler = build_handler('prompt_input_exit')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('Overtime.wav', handler)
  end

  def test_unknown_reason_plays_default
    handler = build_handler('unknown')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('Wins The Game.wav', handler)
  end

  def test_displays_box_score_when_has_turns
    SessionStats.increment_turns(error_occurred: false)

    handler = build_handler('exit')
    handler.call

    assert @box_score_stub.called?, 'Should display box score when turns > 0'
  end

  def test_skips_box_score_when_zero_turns
    handler = build_handler('exit')
    handler.call

    assert_false @box_score_stub.called?, 'Should skip box score when turns = 0'
  end

  def test_resets_stats_after_box_score
    SessionStats.record('Edit')
    SessionStats.increment_turns(error_occurred: false)

    handler = build_handler('exit')
    handler.call

    assert_equal 0, SessionStats.stats['total_tools']
  end

  def test_off_mode_skips_box_score
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\n")
    SessionStats.increment_turns(error_occurred: false)

    handler = build_handler('exit')
    handler.call

    assert_false @box_score_stub.called?
  end

  def test_allows_continue
    result = build_handler('exit').call
    assert_true result['continue']
  end

  def test_suppresses_output
    result = build_handler('exit').call
    assert_true result['suppressOutput']
  end

  private

  def build_handler(reason)
    JamClaudeSessionEndHandler.new({ 'reason' => reason })
  end
end
