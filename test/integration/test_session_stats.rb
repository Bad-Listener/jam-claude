# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/session_stats'

class TestSessionStats < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')
  end

  def test_reset_zeros_all_stats
    SessionStats.reset
    stats = SessionStats.stats

    assert_equal 0, stats['total_tools']
    assert_equal 0, stats['edits']
    assert_equal 0, stats['reads']
    assert_equal 0, stats['writes']
    assert_equal 0, stats['bashes']
    assert_equal 0, stats['permissions']
    assert_equal 0, stats['errors']
    assert_equal 0, stats['turns']
    assert_equal 0, stats['error_turns']
    assert_equal 0, stats['peak_streak']
    assert_false stats['was_on_fire']
  end

  def test_record_edit_increments_edits
    SessionStats.reset
    SessionStats.record('Edit')
    stats = SessionStats.stats

    assert_equal 1, stats['total_tools']
    assert_equal 1, stats['edits']
  end

  def test_record_read_increments_reads
    SessionStats.reset
    SessionStats.record('Read')
    stats = SessionStats.stats

    assert_equal 1, stats['reads']
  end

  def test_record_grep_increments_reads
    SessionStats.reset
    SessionStats.record('Grep')
    stats = SessionStats.stats

    assert_equal 1, stats['reads']
  end

  def test_record_glob_increments_reads
    SessionStats.reset
    SessionStats.record('Glob')
    stats = SessionStats.stats

    assert_equal 1, stats['reads']
  end

  def test_record_write_increments_writes
    SessionStats.reset
    SessionStats.record('Write')
    stats = SessionStats.stats

    assert_equal 1, stats['writes']
  end

  def test_record_bash_increments_bashes
    SessionStats.reset
    SessionStats.record('Bash')
    stats = SessionStats.stats

    assert_equal 1, stats['bashes']
  end

  def test_record_unknown_tool_increments_total_only
    SessionStats.reset
    SessionStats.record('UnknownTool')
    stats = SessionStats.stats

    assert_equal 1, stats['total_tools']
    assert_equal 0, stats['edits']
    assert_equal 0, stats['reads']
    assert_equal 0, stats['writes']
    assert_equal 0, stats['bashes']
  end

  def test_increment_permissions
    SessionStats.reset
    SessionStats.increment_permissions
    assert_equal 1, SessionStats.stats['permissions']
  end

  def test_increment_errors
    SessionStats.reset
    SessionStats.increment_errors
    assert_equal 1, SessionStats.stats['errors']
  end

  def test_increment_turns_without_error
    SessionStats.reset
    SessionStats.increment_turns(error_occurred: false)
    stats = SessionStats.stats

    assert_equal 1, stats['turns']
    assert_equal 0, stats['error_turns']
  end

  def test_increment_turns_with_error
    SessionStats.reset
    SessionStats.increment_turns(error_occurred: true)
    stats = SessionStats.stats

    assert_equal 1, stats['turns']
    assert_equal 1, stats['error_turns']
  end

  def test_update_peak_streak
    SessionStats.reset
    SessionStats.update_peak_streak(3)
    assert_equal 3, SessionStats.stats['peak_streak']

    # Lower streak doesn't overwrite
    SessionStats.update_peak_streak(2)
    assert_equal 3, SessionStats.stats['peak_streak']

    # Higher streak does overwrite
    SessionStats.update_peak_streak(5)
    assert_equal 5, SessionStats.stats['peak_streak']
  end

  def test_was_on_fire_at_streak_3
    SessionStats.reset
    SessionStats.update_peak_streak(2)
    assert_false SessionStats.stats['was_on_fire']

    SessionStats.update_peak_streak(3)
    assert_true SessionStats.stats['was_on_fire']
  end

  def test_multiple_tools_accumulate
    SessionStats.reset
    3.times { SessionStats.record('Edit') }
    2.times { SessionStats.record('Read') }
    stats = SessionStats.stats

    assert_equal 5, stats['total_tools']
    assert_equal 3, stats['edits']
    assert_equal 2, stats['reads']
  end

  def test_corrupt_file_recovery
    write_sandbox_file('jam-stats.json', 'bad json!!!')
    stats = SessionStats.stats
    assert_equal 0, stats['total_tools']
  end
end
