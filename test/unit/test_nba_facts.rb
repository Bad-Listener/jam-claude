# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/nba_facts'

class TestNbaFacts < JamTest::TestCase
  def test_total_facts_at_least_175
    assert_greater_than 174, NbaFacts::ALL_FACTS.size,
                        "Expected >= 175 facts, got #{NbaFacts::ALL_FACTS.size}"
  end

  def test_six_categories_exist
    expected = %i[jam_arcade jam_franchise jam_culture iconic_moments player_quotes oddities]
    expected.each do |cat|
      assert NbaFacts::FACTS_BY_CATEGORY.key?(cat), "Missing category: #{cat}"
    end
  end

  def test_all_categories_have_emojis
    NbaFacts::FACTS_BY_CATEGORY.keys.each do |cat|
      emoji = NbaFacts::CATEGORY_EMOJIS[cat]
      assert_not_nil emoji, "No emoji for #{cat}"
      assert emoji.length > 0, "Empty emoji for #{cat}"
    end
  end

  def test_no_duplicate_facts
    all = NbaFacts::ALL_FACTS
    dupes = all.select { |f| all.count(f) > 1 }.uniq
    assert_empty dupes, "Duplicate facts found: #{dupes.first(3).inspect}"
  end

  def test_random_returns_string
    fact = NbaFacts.random
    assert_instance_of String, fact
    assert fact.length > 0
  end

  def test_random_with_category_returns_hash
    result = NbaFacts.random_with_category
    assert_instance_of Hash, result
    assert_not_nil result[:emoji]
    assert_not_nil result[:fact]
    assert_not_nil result[:category]
  end

  def test_random_with_category_has_valid_category
    result = NbaFacts.random_with_category
    assert_includes NbaFacts::FACTS_BY_CATEGORY.keys, result[:category]
  end

  def test_each_category_has_facts
    NbaFacts::FACTS_BY_CATEGORY.each do |cat, facts|
      assert_greater_than 0, facts.size, "Category #{cat} is empty"
    end
  end

  def test_all_facts_are_non_empty_strings
    NbaFacts::ALL_FACTS.each_with_index do |fact, i|
      assert_instance_of String, fact, "Fact #{i} is not a string"
      assert fact.strip.length > 0, "Fact #{i} is empty"
    end
  end
end
