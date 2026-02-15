# frozen_string_literal: true

require 'rbconfig'
require_relative 'fire_colors'

# BoxScore - Display post-game basketball stats for the coding session
#
# Renders an NBA Jam style box score to the terminal on session end.
# Writes directly to /dev/tty to bypass both stdout (JSON hook output) and
# stderr (not displayed during SessionEnd hooks).

module BoxScore
  # Non-fire colors for rating tiers (keep distinctive)
  GREEN = "\e[92m"
  CYAN  = "\e[96m"

  RATING_TIERS = [
    [51, 'HALL OF FAME',   :fire_red],
    [31, 'MVP CANDIDATE',  :gold],
    [16, 'ALL-STAR',       :green],
    [6,  'STARTER',        :cyan],
    [0,  'BENCHWARMER',    :dim]
  ].freeze

  # Box width: 41 inner chars + 2 border chars = 45 total (matches original)
  INNER_WIDTH = 41

  class << self
    def display(stats, peak_streak, was_on_fire)
      output = render(stats, peak_streak, was_on_fire)

      # Write directly to terminal, bypassing stdout (JSON) and stderr
      # SessionEnd hook stderr is not displayed to the user, so we must
      # use /dev/tty (same approach as AsciiBanner in SessionStart)
      tty_path = windows? ? 'CON' : '/dev/tty'
      File.open(tty_path, 'w') { |tty| tty.puts output }
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES, IOError, Errno::EPIPE
      # No terminal available at all — silent fail
    end

    private

    def render(stats, peak_streak, was_on_fire)
      pts = stats['points']
      rating_label, rating_color = determine_rating(pts)
      fire_indicator = was_on_fire ? "  #{FireColors.fire_red}#{FireColors.bold}🔥 ON FIRE#{FireColors.reset}" : ''

      b = FireColors.red_orange  # border color
      r = FireColors.reset
      h = FireColors.gold        # header color
      a = FireColors.amber       # stat label color
      w = "#{FireColors.warm_white}#{FireColors.bold}" # stat values

      lines = []
      lines << ''
      lines << "#{b}  ╔#{'═' * INNER_WIDTH}╗#{r}"
      lines << "#{b}  ║#{r}#{h}#{FireColors.bold}#{'POST-GAME BOX SCORE'.center(INNER_WIDTH)}#{r}#{b}║#{r}"
      lines << "#{b}  ╠#{'═' * INNER_WIDTH}╣#{r}"
      lines << "#{b}  ║#{r}#{' ' * INNER_WIDTH}#{b}║#{r}"
      lines << "#{b}  ║#{r}   #{a}PTS#{r}  #{w}#{pad(pts)}#{r}     #{a}AST#{r}  #{w}#{pad(stats['assists'])}#{r}     #{a}REB#{r}  #{w}#{pad(stats['rebounds'])}#{r}    #{b}║#{r}"
      lines << "#{b}  ║#{r}   #{a}DNK#{r}  #{w}#{pad(stats['dunks'])}#{r}     #{a}STL#{r}  #{w}#{pad(stats['steals'])}#{r}     #{a}BLK#{r}  #{w}#{pad(stats['blocks'])}#{r}    #{b}║#{r}"
      lines << "#{b}  ║#{r}#{' ' * INNER_WIDTH}#{b}║#{r}"
      lines << streak_line(peak_streak, fire_indicator, b, r, a, w)
      lines << "#{b}  ║#{r}#{' ' * INNER_WIDTH}#{b}║#{r}"
      lines << rating_line(rating_label, rating_color, b, r)
      lines << "#{b}  ╚#{'═' * INNER_WIDTH}╝#{r}"
      lines << ''
      lines.join("\n")
    end

    def streak_line(peak_streak, fire_indicator, b, r, a, w)
      # Visible chars without ANSI: "  STREAK  ###" = 13 terminal columns
      # With fire: + "  🔥 ON FIRE" = 12 terminal columns (🔥 is 2-wide)
      visible_len = 13
      visible_len += 12 if fire_indicator != ''
      padding = INNER_WIDTH - visible_len

      "#{b}  ║#{r}  #{a}STREAK#{r}  #{w}#{pad(peak_streak)}#{r}#{fire_indicator}#{' ' * padding}#{b}║#{r}"
    end

    def rating_line(label, color_key, b, r)
      # Map color keys to actual escape codes
      color = case color_key
              when :fire_red then "#{FireColors.fire_red}#{FireColors.bold}"
              when :gold     then "#{FireColors.gold}#{FireColors.bold}"
              when :green    then "#{GREEN}#{FireColors.bold}"
              when :cyan     then "#{CYAN}#{FireColors.bold}"
              when :dim      then FireColors.dim
              else FireColors.warm_white
              end

      # "  RATING: " = 10 visible chars, then label
      visible_len = 10 + label.length
      padding = INNER_WIDTH - visible_len

      "#{b}  ║#{r}  #{FireColors.amber}RATING:#{r} #{color}#{label}#{r}#{' ' * padding}#{b}║#{r}"
    end

    def determine_rating(points)
      RATING_TIERS.each do |threshold, label, color_key|
        return [label, color_key] if points >= threshold
      end
      ['BENCHWARMER', :dim]
    end

    def pad(value)
      [value.to_i, 999].min.to_s.rjust(3)
    end

    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    end
  end
end
