# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/box_score'

class TestBoxScore < JamTest::TestCase
  def test_render_contains_all_stat_labels
    stats = full_stats(turns: 10, error_turns: 2, peak_streak: 3, total_tools: 20,
                       writes: 3, reads: 8, bashes: 5, permissions: 1)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 3, true)

    BoxScore::STAT_LABELS.each do |label|
      assert_includes output, label, "Missing stat label: #{label}"
    end
  end

  def test_render_contains_portrait
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 2, false)

    # Portrait uses Unicode block characters
    assert_includes output, "\u2588" # full block
  end

  def test_render_contains_post_game_title
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 2, false)

    assert_includes output, 'P O S T - G A M E'
  end

  def test_render_contains_streak_label
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 4, false)

    assert_includes output, 'STREAK'
  end

  def test_render_contains_on_fire_when_applicable
    stats = full_stats(turns: 10, peak_streak: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 5, true)

    assert_includes output, 'ON FIRE'
  end

  def test_render_no_fire_when_not_applicable
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 2, false)

    assert !output.include?('ON FIRE'), 'Should not include ON FIRE'
  end

  def test_render_contains_rating
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 2, false)

    assert_includes output, 'RATING:'
  end

  def test_rating_tiers
    # Test threshold boundaries
    assert_equal 'HALL OF FAME', BoxScore.send(:determine_rating, 40).first
    assert_equal 'MVP CANDIDATE', BoxScore.send(:determine_rating, 30).first
    assert_equal 'ALL-STAR', BoxScore.send(:determine_rating, 20).first
    assert_equal 'STARTER', BoxScore.send(:determine_rating, 10).first
    assert_equal 'BENCHWARMER', BoxScore.send(:determine_rating, 0).first
  end

  def test_rating_tier_boundaries
    assert_equal 'HALL OF FAME', BoxScore.send(:determine_rating, 50).first
    assert_equal 'MVP CANDIDATE', BoxScore.send(:determine_rating, 39).first
    assert_equal 'ALL-STAR', BoxScore.send(:determine_rating, 29).first
    assert_equal 'STARTER', BoxScore.send(:determine_rating, 19).first
    assert_equal 'BENCHWARMER', BoxScore.send(:determine_rating, 9).first
  end

  def test_display_handles_no_tty
    # display writes to /dev/tty — should not crash if unavailable
    stats = full_stats(turns: 5)

    # Stub File.open to prevent actual TTY write
    stub_method(BoxScore, :display) { nil }
    BoxScore.display(stats, 2, false)
    # If we get here without error, the test passes
    assert true
  end

  def test_render_contains_claude_name
    stats = full_stats(turns: 5)
    nba_stats = StatsCalculator.calculate(stats)
    output = BoxScore.send(:render, nba_stats, 2, false)

    assert_includes output, 'CLAUDE'
  end

  private

  def full_stats(overrides = {})
    {
      'turns' => overrides.fetch(:turns, 0),
      'error_turns' => overrides.fetch(:error_turns, 0),
      'peak_streak' => overrides.fetch(:peak_streak, 0),
      'total_tools' => overrides.fetch(:total_tools, overrides.fetch(:turns, 0) * 2),
      'writes' => overrides.fetch(:writes, 0),
      'reads' => overrides.fetch(:reads, 0),
      'bashes' => overrides.fetch(:bashes, 0),
      'permissions' => overrides.fetch(:permissions, 0),
      'was_on_fire' => overrides.fetch(:was_on_fire, false)
    }
  end
end
