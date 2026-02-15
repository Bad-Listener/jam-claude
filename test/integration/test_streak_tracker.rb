# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/streak_tracker'

class TestStreakTracker < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(StreakTracker, :STATE_PATH, 'jam-streak.json')
  end

  def test_initial_streak_is_zero
    assert_equal 0, StreakTracker.current_streak
  end

  def test_increment_returns_count
    assert_equal 1, StreakTracker.increment
    assert_equal 2, StreakTracker.increment
    assert_equal 3, StreakTracker.increment
  end

  def test_current_streak_reflects_increments
    StreakTracker.increment
    StreakTracker.increment
    assert_equal 2, StreakTracker.current_streak
  end

  def test_reset_sets_streak_to_zero
    StreakTracker.increment
    StreakTracker.increment
    StreakTracker.reset
    assert_equal 0, StreakTracker.current_streak
  end

  def test_on_fire_at_three
    2.times { StreakTracker.increment }
    assert_false StreakTracker.on_fire?

    StreakTracker.increment
    assert_true StreakTracker.on_fire?
  end

  def test_best_streak_persists_after_reset
    5.times { StreakTracker.increment }
    assert_equal 5, StreakTracker.best_streak

    StreakTracker.reset
    assert_equal 0, StreakTracker.current_streak
    assert_equal 5, StreakTracker.best_streak
  end

  def test_on_fire_cleared_on_reset
    3.times { StreakTracker.increment }
    assert_true StreakTracker.on_fire?

    StreakTracker.reset
    assert_false StreakTracker.on_fire?
  end

  def test_corrupt_file_recovery
    write_sandbox_file('jam-streak.json', 'corrupted data!!!')
    assert_equal 0, StreakTracker.current_streak
    # Should still be able to increment after recovery
    assert_equal 1, StreakTracker.increment
  end

  def test_state_file_created_on_write
    StreakTracker.increment
    assert sandbox_file_exists?('jam-streak.json')
  end

  def test_best_streak_updates_to_highest
    3.times { StreakTracker.increment }
    StreakTracker.reset
    2.times { StreakTracker.increment }

    assert_equal 3, StreakTracker.best_streak
    assert_equal 2, StreakTracker.current_streak
  end
end
