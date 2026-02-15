# frozen_string_literal: true

require_relative '../test_helper'

vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)
require 'claude_hooks'

require_relative '../../hooks/handlers/stop_handler'

class TestStopHandler < JamTest::TestCase
  def setup
    super
    create_sandbox

    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
    sandbox_const(ErrorState, :STATE_FILE, 'jam-error-state.json')
    sandbox_const(ContextualSoundState, :STATE_FILE, 'jam-contextual-state.json')
    sandbox_const(StreakTracker, :STATE_PATH, 'jam-streak.json')
    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')

    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n")

    @play_weighted_stub = stub_method(SoundPlayer, :play_weighted) { true }

    SessionStats.reset
  end

  # ── Error state skips success sound ────────────────────────────────────
  def test_error_state_skips_success_sound
    ErrorState.mark_error!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_false @play_weighted_stub.called?, 'Should skip success sound when error occurred'
  end

  def test_error_state_clears_after_read
    ErrorState.mark_error!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_false ErrorState.read_state['error_occurred'], 'Error state should be cleared'
  end

  def test_error_state_increments_turn_with_error
    ErrorState.mark_error!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_equal 1, SessionStats.stats['error_turns']
  end

  # ── Contextual sound state skips success sound ─────────────────────────
  def test_contextual_state_skips_success_sound
    ContextualSoundState.mark_played!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_false @play_weighted_stub.called?, 'Should skip when contextual sound already played'
  end

  def test_contextual_state_cleared_after_read
    ContextualSoundState.mark_played!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_false ContextualSoundState.read_state['played']
  end

  # ── Streak increments on success ───────────────────────────────────────
  def test_streak_increments_on_success
    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_equal 1, StreakTracker.current_streak
  end

  def test_streak_does_not_increment_on_error
    ErrorState.mark_error!

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_equal 0, StreakTracker.current_streak
  end

  # ── Streak 2 → Heating Up ─────────────────────────────────────────────
  def test_streak_2_heating_up
    StreakTracker.increment # streak = 1

    handler = JamClaudeStopHandler.new({})
    handler.call # streak = 2

    assert @play_weighted_stub.called?
    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?('Heating Up.wav'), 'Streak 2 should play Heating Up'
    assert_equal 1.0, sounds['Heating Up.wav']
  end

  # ── Streak 3-4 → Fire 15% ─────────────────────────────────────────────
  def test_streak_3_fire_15_percent
    2.times { StreakTracker.increment } # streak = 2

    handler = JamClaudeStopHandler.new({})
    handler.call # streak = 3

    assert @play_weighted_stub.called?
    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?("He's on Fire.wav"), 'Streak 3 should include Fire'
    assert_in_range 0.14..0.16, sounds["He's on Fire.wav"]
  end

  # ── Streak 5+ → Fire 30% ──────────────────────────────────────────────
  def test_streak_5_fire_30_percent
    4.times { StreakTracker.increment } # streak = 4

    handler = JamClaudeStopHandler.new({})
    handler.call # streak = 5

    assert @play_weighted_stub.called?
    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?("He's on Fire.wav"), 'Streak 5 should include Fire'
    assert_in_range 0.29..0.31, sounds["He's on Fire.wav"]
  end

  # ── Low mode ────────────────────────────────────────────────────────────
  def test_low_mode_silent_at_streak_0
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")

    handler = JamClaudeStopHandler.new({})
    handler.call

    assert_false @play_weighted_stub.called?, 'Low mode should be silent at streak 1'
  end

  def test_low_mode_heating_up_at_streak_2
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")
    StreakTracker.increment # streak = 1

    handler = JamClaudeStopHandler.new({})
    handler.call # streak = 2

    assert @play_weighted_stub.called?
    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?('Heating Up.wav')
  end

  def test_low_mode_fire_at_streak_3
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")
    2.times { StreakTracker.increment }

    handler = JamClaudeStopHandler.new({})
    handler.call # streak = 3

    assert @play_weighted_stub.called?
    args = @play_weighted_stub.last_args
    sounds = args.first
    assert sounds.key?("He's on Fire.wav")
  end

  # ── Output data ─────────────────────────────────────────────────────────
  def test_allows_continue
    result = JamClaudeStopHandler.new({}).call
    assert_true result['continue']
  end

  def test_suppresses_output
    result = JamClaudeStopHandler.new({}).call
    assert_true result['suppressOutput']
  end

  # ── Peak streak tracking ───────────────────────────────────────────────
  def test_updates_peak_streak
    3.times do
      handler = JamClaudeStopHandler.new({})
      handler.call
    end

    assert_equal 3, SessionStats.stats['peak_streak']
  end
end
