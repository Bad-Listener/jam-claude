# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/fire_colors'

class TestFireColors < JamTest::TestCase
  def setup
    super
    FireColors.instance_variable_set(:@tier, nil)
    FireColors.instance_variable_set(:@no_color, nil)
  end

  # ── Tier detection ──────────────────────────────────────────────────────
  def test_truecolor_detection_via_colorterm
    with_env('COLORTERM' => 'truecolor', 'NO_COLOR' => nil, 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal :truecolor, FireColors.tier
    end
  end

  def test_truecolor_detection_via_24bit
    with_env('COLORTERM' => '24bit', 'NO_COLOR' => nil, 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal :truecolor, FireColors.tier
    end
  end

  def test_256color_detection
    with_env('COLORTERM' => '', 'TERM' => 'xterm-256color', 'NO_COLOR' => nil) do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal :color256, FireColors.tier
    end
  end

  def test_basic_tier_fallback
    with_env('COLORTERM' => '', 'TERM' => 'dumb', 'NO_COLOR' => nil) do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal :basic, FireColors.tier
    end
  end

  # ── Truecolor output ───────────────────────────────────────────────────
  def test_gold_truecolor_code
    with_env('COLORTERM' => 'truecolor', 'NO_COLOR' => nil, 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal "\e[38;2;255;215;0m", FireColors.gold
    end
  end

  def test_fire_red_truecolor_code
    with_env('COLORTERM' => 'truecolor', 'NO_COLOR' => nil, 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal "\e[38;2;255;51;0m", FireColors.fire_red
    end
  end

  # ── 256-color output ───────────────────────────────────────────────────
  def test_gold_256_code
    with_env('COLORTERM' => '', 'TERM' => 'xterm-256color', 'NO_COLOR' => nil) do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal "\e[38;5;220m", FireColors.gold
    end
  end

  # ── NO_COLOR ────────────────────────────────────────────────────────────
  def test_no_color_returns_empty_strings
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal '', FireColors.gold
      assert_equal '', FireColors.reset
      assert_equal '', FireColors.bold
      assert_equal '', FireColors.dim
    end
  end

  def test_no_color_tier_is_basic
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal :basic, FireColors.tier
    end
  end

  def test_no_color_wrap_returns_plain_text
    with_env('NO_COLOR' => '1') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal 'hello', FireColors.wrap('hello', :gold)
    end
  end

  # ── All 9 palette colors accessible ────────────────────────────────────
  def test_all_palette_colors_accessible
    with_env('COLORTERM' => 'truecolor', 'NO_COLOR' => nil, 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      %i[gold amber orange dark_orange red_orange deep_red fire_red warm_white dim_orange].each do |color|
        result = FireColors.send(color)
        assert result.length > 0, "#{color} returned empty string"
        assert_match(/\e\[38;2;/, result, "#{color} not in truecolor format")
      end
    end
  end

  # ── Reset and formatting ───────────────────────────────────────────────
  def test_reset_code
    with_env('NO_COLOR' => nil, 'COLORTERM' => 'truecolor', 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal "\e[0m", FireColors.reset
    end
  end

  def test_bold_code
    with_env('NO_COLOR' => nil, 'COLORTERM' => 'truecolor', 'TERM' => '') do
      FireColors.instance_variable_set(:@tier, nil)
      FireColors.instance_variable_set(:@no_color, nil)

      assert_equal "\e[1m", FireColors.bold
    end
  end

  # ── LOGO_GRADIENT ──────────────────────────────────────────────────────
  def test_logo_gradient_has_6_colors
    assert_equal 6, FireColors::LOGO_GRADIENT.size
  end

  def test_logo_gradient_colors_all_in_palette
    FireColors::LOGO_GRADIENT.each do |color|
      assert FireColors::PALETTE.key?(color), "#{color} not in PALETTE"
    end
  end
end
