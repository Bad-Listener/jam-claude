# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/error_sound_mapper'

class TestErrorSoundMapper < JamTest::TestCase
  def test_all_error_categories_have_mappings
    categories = %i[permission_denied file_not_found exit_failure command_not_found
                    signal_termination network_error syntax_error state_corruption generic_error]

    categories.each do |cat|
      mapping = ErrorSoundMapper.sound_for_category(cat)
      assert mapping.is_a?(Hash), "No mapping for #{cat}"
      assert_greater_than 0, mapping.size, "Empty mapping for #{cat}"
    end
  end

  def test_permission_denied_returns_rejected
    assert_equal 'Rejected.wav', ErrorSoundMapper.select_sound(:permission_denied)
  end

  def test_file_not_found_returns_off_the_rim
    assert_equal '54 - Off the rim.wav', ErrorSoundMapper.select_sound(:file_not_found)
  end

  def test_command_not_found_returns_wild_shot
    assert_equal 'Wild Shot.wav', ErrorSoundMapper.select_sound(:command_not_found)
  end

  def test_signal_termination_returns_shove
    assert_equal '53 - Shove.wav', ErrorSoundMapper.select_sound(:signal_termination)
  end

  def test_network_error_returns_intercepted
    assert_equal 'Intercepted.wav', ErrorSoundMapper.select_sound(:network_error)
  end

  def test_syntax_error_returns_ugly_shot
    assert_equal 'Ugly Shot.wav', ErrorSoundMapper.select_sound(:syntax_error)
  end

  def test_state_corruption_returns_turnover
    assert_equal 'The Turnover.wav', ErrorSoundMapper.select_sound(:state_corruption)
  end

  def test_exit_failure_returns_valid_sound
    valid_sounds = ['Terrible Shot.wav', 'No Good.wav']
    100.times do
      sound = ErrorSoundMapper.select_sound(:exit_failure)
      assert_includes valid_sounds, sound
    end
  end

  def test_generic_error_returns_valid_sound
    valid_sounds = ['No Good.wav', 'Wild Shot.wav']
    100.times do
      sound = ErrorSoundMapper.select_sound(:generic_error)
      assert_includes valid_sounds, sound
    end
  end

  def test_unknown_category_falls_back_to_generic
    mapping = ErrorSoundMapper.sound_for_category(:nonexistent_category)
    generic = ErrorSoundMapper.sound_for_category(:generic_error)
    assert_equal generic, mapping
  end

  def test_weights_sum_to_one_for_each_category
    ErrorSoundMapper::SOUND_MAPPINGS.each do |category, sounds|
      total = sounds.values.sum
      assert_in_range 0.99..1.01, total, "Weights for #{category} sum to #{total}"
    end
  end
end
