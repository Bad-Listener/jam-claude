# frozen_string_literal: true

require 'rbconfig'
require_relative 'fire_colors'
require_relative 'stats_calculator'

# BoxScore - NBA Jam 1993 arcade halftime screen for the coding session
#
# Two-panel layout: portrait silhouette (left) + vertical stats (right).
# Raw tool counts are converted to NBA-realistic stats via StatsCalculator.
# Writes directly to /dev/tty to bypass stdout (JSON) and stderr.

module BoxScore
  GREEN = "\e[92m"
  CYAN  = "\e[96m"

  # Rating tiers based on calculated PTS (not raw tool count)
  RATING_TIERS = [
    [40, 'HALL OF FAME',   :fire_red],
    [30, 'MVP CANDIDATE',  :gold],
    [20, 'ALL-STAR',       :green],
    [10, 'STARTER',        :cyan],
    [0,  'BENCHWARMER',    :dim]
  ].freeze

  # 46 inner chars + 2 border = 48 total (fits 80-col terminals)
  INNER_WIDTH = 46

  # Portrait silhouette — flat-top style (10 chars inner, 90s arcade vibe)
  PORTRAIT_ART = [
    "\u2591\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2591",
    "\u2591\u2588\u2593\u2593\u2593\u2593\u2593\u2593\u2588\u2591",
    "\u2591\u2588\u2593\u2593\u2593\u2593\u2593\u2593\u2588\u2591",
    "\u2591\u2591\u2588\u2593\u2593\u2593\u2593\u2588\u2591\u2591",
    "\u2591\u2591\u2591\u2591\u2593\u2593\u2591\u2591\u2591\u2591",
    "\u2591\u2584\u2588\u2588\u2588\u2588\u2588\u2588\u2584\u2591"
  ].freeze

  # Stat labels and their corresponding StatsCalculator keys (8 rows = 8 portrait lines)
  STAT_LABELS = ["FG'S:", '3 PTS:', 'POINTS:', 'DUNKS:', 'ASSISTS:', 'STEALS:', 'BLOCKS:', 'REBNDS:'].freeze
  STAT_KEYS   = %w[fg three_made pts dnk ast stl blk reb].freeze

  class << self
    def display(stats, peak_streak, was_on_fire)
      nba_stats = StatsCalculator.calculate(stats)
      output = render(nba_stats, peak_streak, was_on_fire)

      tty_path = windows? ? 'CON' : '/dev/tty'
      File.open(tty_path, 'w') { |tty| tty.puts output }
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES, IOError, Errno::EPIPE
      # No terminal available — silent fail
    end

    private

    def render(nba_stats, peak_streak, was_on_fire)
      b  = FireColors.red_orange                     # border
      r  = FireColors.reset
      hb = "#{FireColors.gold}#{FireColors.bold}"    # header bold
      pf = FireColors.amber                          # portrait frame
      pa = FireColors.dim_orange                     # portrait art
      a  = FireColors.amber                          # stat labels
      w  = "#{FireColors.warm_white}#{FireColors.bold}" # stat values

      portrait = build_portrait(pf, pa, r)
      stat_values = STAT_KEYS.map { |key| nba_stats[key] }

      lines = []
      lines << ''
      lines << "#{b}  \u2554#{'═' * INNER_WIDTH}\u2557#{r}"
      lines << header_line(nba_stats['pts'], hb, b, r)
      lines << "#{b}  \u2560#{'═' * INNER_WIDTH}\u2563#{r}"
      lines << empty_line(b, r)

      # Portrait + stats (8 lines: frame_top + 6 art + frame_bot)
      8.times do |i|
        lines << stat_row(portrait[i], STAT_LABELS[i], stat_values[i], a, w, b, r)
      end

      # Name plate under portrait
      lines << name_row('CLAUDE', 6, pf, b, r)
      lines << name_row('AI', 8, a, b, r)
      lines << empty_line(b, r)

      # Bottom section
      lines << "#{b}  \u2560#{'═' * INNER_WIDTH}\u2563#{r}"
      lines << streak_row(peak_streak, was_on_fire, a, w, b, r)
      lines << rating_row(nba_stats['pts'], b, r)
      lines << "#{b}  \u255a#{'═' * INNER_WIDTH}\u255d#{r}"
      lines << ''

      lines.join("\n")
    end

    # Header: points score + "P O S T - G A M E" title
    # Visible: 2 + 3 + 8 + 17 = 30, padding = 16
    def header_line(pts, hb, b, r)
      pts_str = pts.to_s.rjust(3)
      title = 'P O S T - G A M E'
      padding = INNER_WIDTH - 30
      "#{b}  \u2551#{r}  #{hb}#{pts_str}#{r}        #{hb}#{title}#{r}#{' ' * padding}#{b}\u2551#{r}"
    end

    def empty_line(b, r)
      "#{b}  \u2551#{r}#{' ' * INNER_WIDTH}#{b}\u2551#{r}"
    end

    # Build 8 colored portrait strings (frame_top + 6 art + frame_bot)
    def build_portrait(pf, pa, r)
      lines = []
      lines << "#{pf}\u250c#{'─' * 10}\u2510#{r}"
      PORTRAIT_ART.each do |art|
        lines << "#{pf}\u2502#{r}#{pa}#{art}#{r}#{pf}\u2502#{r}"
      end
      lines << "#{pf}\u2514#{'─' * 10}\u2518#{r}"
      lines
    end

    # Body line: 3-space indent + portrait (12) + 4-space gap + label (10) + value (3) + padding (14)
    # Visible: 3 + 12 + 4 + 10 + 3 + 14 = 46
    def stat_row(portrait_colored, label, value, a, w, b, r)
      stat = "#{a}#{label.ljust(10)}#{r}#{w}#{pad(value)}#{r}"
      "#{b}  \u2551#{r}   #{portrait_colored}    #{stat}#{' ' * 14}#{b}\u2551#{r}"
    end

    # Name plate centered under portrait
    def name_row(text, indent, color, b, r)
      visible_len = indent + text.length
      padding = INNER_WIDTH - visible_len
      "#{b}  \u2551#{r}#{' ' * indent}#{color}#{text}#{r}#{' ' * padding}#{b}\u2551#{r}"
    end

    # Streak line with optional fire indicator
    # Without fire: "   STREAK    ###" = 16 visible, padding = 30
    # With fire:    + "   🔥 ON FIRE" = +13 visible (🔥=2 cols), padding = 17
    def streak_row(peak_streak, was_on_fire, a, w, b, r)
      fire = ''
      visible_len = 16

      if was_on_fire
        fire = "   #{FireColors.fire_red}#{FireColors.bold}\u{1f525} ON FIRE#{r}"
        visible_len += 13
      end

      padding = INNER_WIDTH - visible_len
      "#{b}  \u2551#{r}   #{a}STREAK#{r}    #{w}#{pad(peak_streak)}#{r}#{fire}#{' ' * padding}#{b}\u2551#{r}"
    end

    # Rating line
    # Visible: "   RATING: " (11) + label
    def rating_row(pts, b, r)
      label, color_key = determine_rating(pts)
      color = rating_color(color_key)
      visible_len = 11 + label.length
      padding = INNER_WIDTH - visible_len
      "#{b}  \u2551#{r}   #{FireColors.amber}RATING:#{r} #{color}#{label}#{r}#{' ' * padding}#{b}\u2551#{r}"
    end

    def determine_rating(pts)
      RATING_TIERS.each do |threshold, label, color_key|
        return [label, color_key] if pts >= threshold
      end
      ['BENCHWARMER', :dim]
    end

    def rating_color(color_key)
      case color_key
      when :fire_red then "#{FireColors.fire_red}#{FireColors.bold}"
      when :gold     then "#{FireColors.gold}#{FireColors.bold}"
      when :green    then "#{GREEN}#{FireColors.bold}"
      when :cyan     then "#{CYAN}#{FireColors.bold}"
      when :dim      then FireColors.dim
      else FireColors.warm_white
      end
    end

    def pad(value)
      [value.to_i, 999].min.to_s.rjust(3)
    end

    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    end
  end
end
