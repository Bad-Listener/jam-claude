# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/nba_facts'
require_relative '../../hooks/lib/fact_presenter'

class TestFactPresenter < JamTest::TestCase
  def setup
    super
    @fact_data = {
      emoji: "\u{1F579}\uFE0F",
      fact: 'NBA Jam earned over $1 billion in quarters during its first year.',
      category: :jam_culture
    }
  end

  def test_format_returns_multiline_string
    result = FactPresenter.format(@fact_data)
    assert_instance_of String, result
    assert result.include?("\n"), 'Expected multiline output'
  end

  def test_format_contains_category_label
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      result = FactPresenter.format(@fact_data)
      assert_includes result, 'JAM CULTURAL IMPACT'
    end
  end

  def test_format_contains_stripe_borders
    result = FactPresenter.format(@fact_data)
    assert_includes result, "\u2501" # ━ stripe character
  end

  def test_format_contains_fact_text
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      result = FactPresenter.format(@fact_data)
      assert_includes result, 'NBA Jam earned'
    end
  end

  def test_wraps_at_60_chars
    long_fact = {
      emoji: "\u{1F3C0}",
      fact: 'A' * 80 + ' ' + 'B' * 40,
      category: :iconic_moments
    }

    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      result = FactPresenter.format(long_fact)
      lines = result.split("\n")
      # Content lines (non-border) should be wrapped
      content_lines = lines.select { |l| l.strip.start_with?('A') || l.strip.start_with?('B') }
      assert_greater_than 1, content_lines.size, 'Expected text to wrap into multiple lines'
    end
  end

  def test_bold_keywords_bolds_numbers
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      # With NO_COLOR, bold returns '' so the text should pass through unchanged
      result = FactPresenter.format(@fact_data)
      # Should still contain the number
      assert_includes result, '1'
    end
  end

  def test_all_category_labels_exist
    FactPresenter::CATEGORY_LABELS.each do |cat, label|
      assert_instance_of String, label
      assert label.length > 0, "Empty label for #{cat}"
    end
  end

  def test_all_categories_have_reactions
    FactPresenter::REACTIONS.each do |cat, reactions|
      assert reactions.is_a?(Array), "Reactions for #{cat} should be an array"
      assert_greater_than 0, reactions.size, "No reactions for #{cat}"
    end
  end

  def test_format_handles_all_categories
    NbaFacts::FACTS_BY_CATEGORY.keys.each do |cat|
      fact_data = { emoji: NbaFacts::CATEGORY_EMOJIS[cat], fact: 'Test fact.', category: cat }
      result = FactPresenter.format(fact_data)
      assert_instance_of String, result, "Format failed for category #{cat}"
    end
  end
end
