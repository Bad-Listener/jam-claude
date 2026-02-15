# frozen_string_literal: true

# StatsCalculator - Convert raw session stats into NBA-realistic display stats
#
# Takes raw tool counts and derives basketball stats that are mathematically
# consistent: PTS = (FG - 3PT) * 2 + 3PT * 3, FG <= FGA, etc.
#
# All formulas are pure functions — no side effects, no state mutation.

module StatsCalculator
  class << self
    # Convert raw session stats hash into NBA display stats hash
    def calculate(stats)
      turns       = stats['turns'].to_i
      error_turns = stats['error_turns'].to_i
      peak_streak = stats['peak_streak'].to_i
      total_tools = stats['total_tools'].to_i
      writes      = stats['writes'].to_i
      reads       = stats['reads'].to_i
      bashes      = stats['bashes'].to_i
      permissions = stats['permissions'].to_i

      return zero_stats if turns == 0

      # Field goals: turns are shot attempts, error turns are misses
      fga = turns
      fg  = turns - error_turns

      # Three-pointers: streak-driven (hot shooting = threes)
      three_made = [peak_streak - 2, 0].max
      three_made = [three_made, fg / 2].min
      three_att  = three_made + [error_turns, (three_made * 0.5).ceil].min
      three_att  = [three_att, (fga * 0.45).ceil].min

      # Points: 2PT + 3PT scoring
      pts = (fg - three_made) * 2 + three_made * 3

      # Counting stats: derived from tool usage, capped to realistic ranges
      dnk = [writes + peak_streak / 4, fg].min
      ast = [reads / 4, (turns * 0.6).floor].min
      stl = [bashes / 3, 5].min
      blk = [permissions, 5].min
      reb = [(total_tools.to_f / [turns, 1].max * 1.2).floor, 15].min

      {
        'fg' => fg, 'fga' => fga,
        'three_made' => three_made, 'three_att' => three_att,
        'pts' => pts, 'dnk' => dnk, 'ast' => ast,
        'stl' => stl, 'blk' => blk, 'reb' => reb
      }
    end

    private

    def zero_stats
      {
        'fg' => 0, 'fga' => 0,
        'three_made' => 0, 'three_att' => 0,
        'pts' => 0, 'dnk' => 0, 'ast' => 0,
        'stl' => 0, 'blk' => 0, 'reb' => 0
      }
    end
  end
end
