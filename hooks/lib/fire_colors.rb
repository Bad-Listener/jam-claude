# frozen_string_literal: true

# FireColors - Fire gradient palette with automatic terminal capability detection
#
# Provides NBA JAM arcade-inspired red-to-gold gradient colors at 3 quality tiers:
#   Truecolor (24-bit) → 256-color → Basic 16-color
#
# Detection runs once on first access and is memoized for the process lifetime.
# Respects NO_COLOR convention (https://no-color.org/).

module FireColors
  # Color definitions: [name, hex, truecolor_rgb, color256_code, basic_code]
  PALETTE = {
    gold:        { rgb: [255, 215, 0],   c256: '220', basic: '93' },
    amber:       { rgb: [255, 194, 0],   c256: '214', basic: '93' },
    orange:      { rgb: [255, 165, 0],   c256: '208', basic: '93' },
    dark_orange: { rgb: [255, 140, 0],   c256: '208', basic: '33' },
    red_orange:  { rgb: [255, 102, 0],   c256: '202', basic: '91' },
    deep_red:    { rgb: [224, 64, 0],    c256: '160', basic: '91' },
    fire_red:    { rgb: [255, 51, 0],    c256: '196', basic: '91' },
    warm_white:  { rgb: [255, 245, 230], c256: '97',  basic: '97' },
    dim_orange:  { rgb: [204, 136, 68],  c256: '172', basic: '33' }
  }.freeze

  # Logo gradient: top-to-bottom fire effect (6 lines)
  LOGO_GRADIENT = %i[gold amber orange dark_orange red_orange deep_red].freeze

  class << self
    # Terminal capability detection — memoized
    def tier
      @tier ||= detect_tier
    end

    # Named color accessors — each returns the appropriate escape code
    PALETTE.each_key do |name|
      define_method(name) do
        color_code(name)
      end
    end

    def reset
      return '' if no_color?
      "\e[0m"
    end

    def bold
      return '' if no_color?
      "\e[1m"
    end

    def dim
      return '' if no_color?
      "\e[2m"
    end

    # Wrap text in color + reset
    def wrap(text, color_name)
      return text if no_color?
      "#{color_code(color_name)}#{text}#{reset}"
    end

    # Check if colors are disabled
    def no_color?
      @no_color = ENV.key?('NO_COLOR') if @no_color.nil?
      @no_color
    end

    private

    def detect_tier
      return :basic if no_color?

      colorterm = ENV['COLORTERM'].to_s.downcase
      return :truecolor if colorterm.include?('truecolor') || colorterm.include?('24bit')

      term = ENV['TERM'].to_s.downcase
      return :color256 if term.include?('256color')

      :basic
    end

    def color_code(name)
      return '' if no_color?

      spec = PALETTE[name]
      return '' unless spec

      case tier
      when :truecolor
        r, g, b = spec[:rgb]
        "\e[38;2;#{r};#{g};#{b}m"
      when :color256
        "\e[38;5;#{spec[:c256]}m"
      else
        "\e[#{spec[:basic]}m"
      end
    end
  end
end
