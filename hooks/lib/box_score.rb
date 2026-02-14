# frozen_string_literal: true

require 'rbconfig'

# BoxScore - Display post-game basketball stats for the coding session
#
# Renders an NBA Jam style box score to the terminal on session end.
# Writes to stderr to bypass stdout JSON (which Claude Code parses as hook output).
# Falls back to /dev/tty if stderr is unavailable.

module BoxScore
  # ANSI color codes
  YELLOW = "\e[93m"
  WHITE  = "\e[97m"
  CYAN   = "\e[96m"
  GREEN  = "\e[92m"
  RED    = "\e[91m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
  RESET  = "\e[0m"

  RATING_TIERS = [
    [51, 'HALL OF FAME',   RED],
    [31, 'MVP CANDIDATE',  YELLOW],
    [16, 'ALL-STAR',       GREEN],
    [6,  'STARTER',        CYAN],
    [0,  'BENCHWARMER',    DIM]
  ].freeze

  class << self
    def display(stats, peak_streak, was_on_fire)
      output = render(stats, peak_streak, was_on_fire)

      # Primary: write to stderr (Claude Code displays hook stderr to user)
      $stderr.puts output
    rescue IOError, Errno::EPIPE
      # stderr unavailable, try /dev/tty as fallback
      tty_path = windows? ? 'CON' : '/dev/tty'
      File.open(tty_path, 'w') { |tty| tty.puts output }
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES
      # No terminal available at all — silent fail
    end

    private

    def render(stats, peak_streak, was_on_fire)
      pts = stats['points']
      rating_label, rating_color = determine_rating(pts)
      fire_indicator = was_on_fire ? "  #{RED}ON FIRE#{RESET}" : ''

      lines = []
      lines << ''
      lines << "#{YELLOW}  +-----------------------------------------+#{RESET}"
      lines << "#{YELLOW}  |#{WHITE}#{BOLD}        POST-GAME BOX SCORE              #{RESET}#{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  +-----------------------------------------+#{RESET}"
      lines << "#{YELLOW}  |#{RESET}                                         #{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}   #{WHITE}PTS#{RESET}  #{pad(pts)}     #{WHITE}AST#{RESET}  #{pad(stats['assists'])}     #{WHITE}REB#{RESET}  #{pad(stats['rebounds'])}    #{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}   #{WHITE}DNK#{RESET}  #{pad(stats['dunks'])}     #{WHITE}STL#{RESET}  #{pad(stats['steals'])}     #{WHITE}BLK#{RESET}  #{pad(stats['blocks'])}    #{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}                                         #{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}  #{WHITE}STREAK#{RESET}  #{pad(peak_streak)}#{fire_indicator}#{' ' * pad_fire(was_on_fire)}#{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}                                         #{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  |#{RESET}  #{WHITE}RATING:#{RESET} #{rating_color}#{BOLD}#{rating_label}#{RESET}#{' ' * pad_rating(rating_label)}#{YELLOW}|#{RESET}"
      lines << "#{YELLOW}  +-----------------------------------------+#{RESET}"
      lines << ''
      lines.join("\n")
    end

    def determine_rating(points)
      RATING_TIERS.each do |threshold, label, color|
        return [label, color] if points >= threshold
      end
      ['BENCHWARMER', DIM]
    end

    def pad(value)
      [value.to_i, 999].min.to_s.rjust(3)
    end

    # Calculate trailing spaces for the STREAK line to align the right border
    # Inner content = "  STREAK  ###" = 13 visible chars, need 41 total
    # With fire: adds "  ON FIRE" = 9 visible chars → 41 - 13 - 9 = 19
    # Without fire: 41 - 13 = 28
    def pad_fire(was_on_fire)
      was_on_fire ? 19 : 28
    end

    # Calculate trailing spaces for the RATING line to align the right border
    # "  RATING: LABEL" — total content area is 41 chars
    def pad_rating(label)
      41 - 10 - label.length
    end

    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    end
  end
end
