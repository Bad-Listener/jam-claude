# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/stats_calculator'

class TestStatsCalculator < JamTest::TestCase
  def test_zero_turns_returns_zero_stats
    stats = base_stats(turns: 0)
    result = StatsCalculator.calculate(stats)

    assert_equal 0, result['pts']
    assert_equal 0, result['fg']
    assert_equal 0, result['fga']
    assert_equal 0, result['three_made']
    assert_equal 0, result['three_att']
    assert_equal 0, result['dnk']
    assert_equal 0, result['ast']
    assert_equal 0, result['stl']
    assert_equal 0, result['blk']
    assert_equal 0, result['reb']
  end

  def test_points_formula_two_pointers_only
    # 10 turns, 0 errors, 0 streak → no threes
    stats = base_stats(turns: 10, error_turns: 0, peak_streak: 0)
    result = StatsCalculator.calculate(stats)

    # FG = turns - error_turns = 10
    assert_equal 10, result['fg']
    assert_equal 10, result['fga']
    # three_made = max(peak_streak - 2, 0) = 0
    assert_equal 0, result['three_made']
    # PTS = (FG - 3PT) * 2 + 3PT * 3 = 10 * 2 = 20
    assert_equal 20, result['pts']
  end

  def test_points_formula_with_three_pointers
    # Peak streak 5 → three_made = max(5 - 2, 0) = 3
    stats = base_stats(turns: 10, error_turns: 0, peak_streak: 5)
    result = StatsCalculator.calculate(stats)

    assert_equal 3, result['three_made']
    # PTS = (10 - 3) * 2 + 3 * 3 = 14 + 9 = 23
    assert_equal 23, result['pts']
  end

  def test_fg_accounts_for_errors
    stats = base_stats(turns: 10, error_turns: 3)
    result = StatsCalculator.calculate(stats)

    assert_equal 7, result['fg']
    assert_equal 10, result['fga']
  end

  def test_steals_capped_at_five
    stats = base_stats(turns: 5, bashes: 30)
    result = StatsCalculator.calculate(stats)

    assert_in_range 0..5, result['stl']
  end

  def test_blocks_capped_at_five
    stats = base_stats(turns: 5, permissions: 20)
    result = StatsCalculator.calculate(stats)

    assert_in_range 0..5, result['blk']
  end

  def test_rebounds_capped_at_fifteen
    stats = base_stats(turns: 5, total_tools: 500)
    result = StatsCalculator.calculate(stats)

    assert_in_range 0..15, result['reb']
  end

  def test_dunks_from_writes_and_streak
    stats = base_stats(turns: 10, writes: 5, peak_streak: 4)
    result = StatsCalculator.calculate(stats)

    # dnk = min(writes + peak_streak/4, fg) = min(5 + 1, 10) = 6
    assert_equal 6, result['dnk']
  end

  def test_assists_from_reads
    stats = base_stats(turns: 20, reads: 40)
    result = StatsCalculator.calculate(stats)

    # ast = min(reads/4, turns * 0.6) = min(10, 12) = 10
    assert_equal 10, result['ast']
  end

  def test_three_pointers_capped_at_half_fg
    # Huge streak but few turns → threes capped at fg/2
    stats = base_stats(turns: 4, error_turns: 0, peak_streak: 20)
    result = StatsCalculator.calculate(stats)

    # FG = 4, three_made = min(18, 4/2) = 2
    assert_in_range 0..2, result['three_made']
  end

  def test_all_stat_keys_present
    stats = base_stats(turns: 5)
    result = StatsCalculator.calculate(stats)

    expected_keys = %w[fg fga three_made three_att pts dnk ast stl blk reb]
    expected_keys.each do |key|
      assert_not_nil result[key], "Missing key: #{key}"
    end
  end

  private

  def base_stats(overrides = {})
    {
      'turns' => overrides.fetch(:turns, 0),
      'error_turns' => overrides.fetch(:error_turns, 0),
      'peak_streak' => overrides.fetch(:peak_streak, 0),
      'total_tools' => overrides.fetch(:total_tools, overrides.fetch(:turns, 0)),
      'writes' => overrides.fetch(:writes, 0),
      'reads' => overrides.fetch(:reads, 0),
      'bashes' => overrides.fetch(:bashes, 0),
      'permissions' => overrides.fetch(:permissions, 0)
    }
  end
end
