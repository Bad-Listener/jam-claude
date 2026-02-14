# frozen_string_literal: true

# FactPresenter - Transform NBA facts into engaging TikTok-style presentation
# Formats facts with colored stripes, category labels, wrapped text, and reactions

module FactPresenter
  # ANSI color codes (match BoxScore pattern)
  YELLOW = "\e[93m"  # Stripes, reactions
  WHITE  = "\e[97m"  # Fact text
  CYAN   = "\e[96m"  # Category labels
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
  RESET  = "\e[0m"

  # Layout constants
  STRIPE = '━'  # Unicode U+2501
  STRIPE_WIDTH = 62
  CONTENT_WIDTH = 58  # Allows 2-char padding on each side

  # Human-readable category labels
  CATEGORY_LABELS = {
    jam_arcade:     'JAM ARCADE TRIVIA',
    jam_franchise:  'JAM FRANCHISE HISTORY',
    jam_culture:    'JAM CULTURAL IMPACT',
    iconic_moments: 'ICONIC NBA MOMENTS',
    player_quotes:  'LEGENDARY QUOTES',
    oddities:       'NBA ODDITIES'
  }.freeze

  # Category-specific reaction lines (random selection)
  REACTIONS = {
    jam_arcade:     ['💡 The 90s were built different', '🎮 Peak arcade culture'],
    jam_franchise:  ['📀 Console wars nostalgia unlocked', '🎮 Port wars were real'],
    jam_culture:    ['💰 Cultural reset moment', '📈 Changed the game forever'],
    iconic_moments: ['🏆 This is why we watch', '⭐ Absolutely legendary'],
    player_quotes:  ['💬 No notes, just facts', '🗣️ Tell them why you mad'],
    oddities:       ['🤯 Wait, seriously?', '❓ The more you know']
  }.freeze

  class << self
    # Main public API - format a fact with TikTok-style presentation
    # @param fact_data [Hash] with :emoji, :fact, :category keys
    # @return [String] formatted multiline presentation
    def format(fact_data)
      emoji = fact_data[:emoji]
      fact_text = fact_data[:fact]
      category = fact_data[:category]

      # Get category label and reaction
      label = CATEGORY_LABELS[category] || 'NBA TRIVIA'
      reaction = REACTIONS[category]&.sample || '💡 Legendary'

      # Build presentation
      lines = []
      lines << "   #{YELLOW}#{STRIPE * STRIPE_WIDTH}#{RESET}"
      lines << "   #{emoji}  #{CYAN}#{BOLD}#{label}#{RESET}"
      lines << ""

      # Wrap and format fact text
      wrapped_lines = wrap_fact(fact_text)
      wrapped_lines.each do |line|
        lines << "   #{WHITE}#{bold_keywords(line)}#{RESET}"
      end

      lines << ""
      lines << "   #{YELLOW}#{DIM}#{reaction}#{RESET}"
      lines << "   #{YELLOW}#{STRIPE * STRIPE_WIDTH}#{RESET}"

      lines.join("\n")
    end

    private

    # Wrap text to CONTENT_WIDTH, preserving word boundaries
    # @param text [String] the fact text to wrap
    # @return [Array<String>] array of wrapped lines
    def wrap_fact(text)
      words = text.split
      lines = []
      current_line = ""

      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"

        if test_line.length <= CONTENT_WIDTH
          current_line = test_line
        else
          lines << current_line unless current_line.empty?
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines
    end

    # Apply bold formatting to numbers, currency, and superlatives
    # @param text [String] line of text to process
    # @return [String] text with ANSI bold codes inserted
    def bold_keywords(text)
      # Bold numbers (including decimals, commas, percentages)
      text = text.gsub(/\b(\d+(?:,\d{3})*(?:\.\d+)?%?)\b/, "#{BOLD}\\1#{RESET}#{WHITE}")

      # Bold currency (e.g., $2,400, $1 billion)
      text = text.gsub(/(\$\d+(?:,\d{3})*(?:\.\d+)?(?:\s*(?:million|billion))?)/, "#{BOLD}\\1#{RESET}#{WHITE}")

      # Bold superlatives (case-insensitive)
      text = text.gsub(/\b(first|last|only|never|most|highest|lowest|fastest|greatest)\b/i, "#{BOLD}\\1#{RESET}#{WHITE}")

      text
    end
  end
end
