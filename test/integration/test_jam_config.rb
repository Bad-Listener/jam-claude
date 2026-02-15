# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/jam_config'

class TestJamConfig < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
  end

  def test_default_mode_is_off
    assert_equal 'off', JamConfig.mode
  end

  def test_default_frequency_is_normal
    assert_equal 'normal', JamConfig.frequency
  end

  def test_jam_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\n")
    assert_equal 'jam', JamConfig.mode
    assert_true JamConfig.jam?
    assert_false JamConfig.off?
  end

  def test_off_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\n")
    assert_equal 'off', JamConfig.mode
    assert_true JamConfig.off?
    assert_false JamConfig.jam?
  end

  def test_frequent_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=frequent\n")
    assert_true JamConfig.frequent?
    assert_false JamConfig.normal?
    assert_false JamConfig.low?
  end

  def test_normal_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n")
    assert_true JamConfig.normal?
    assert_false JamConfig.frequent?
    assert_false JamConfig.low?
  end

  def test_low_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")
    assert_true JamConfig.low?
    assert_false JamConfig.frequent?
    assert_false JamConfig.normal?
  end

  def test_frequency_predicates_require_jam_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\nSOUND_FREQUENCY=frequent\n")
    assert_false JamConfig.frequent?, 'frequent? should be false when mode is off'
    assert_false JamConfig.normal?, 'normal? should be false when mode is off'
    assert_false JamConfig.low?, 'low? should be false when mode is off'
  end

  def test_invalid_mode_defaults_to_off
    write_sandbox_file('sounds.conf', "SOUND_MODE=invalid\n")
    assert_equal 'off', JamConfig.mode
  end

  def test_invalid_frequency_defaults_to_normal
    write_sandbox_file('sounds.conf', "SOUND_FREQUENCY=invalid\n")
    assert_equal 'normal', JamConfig.frequency
  end

  def test_missing_config_file
    # No file written → defaults
    assert_equal 'off', JamConfig.mode
    assert_equal 'normal', JamConfig.frequency
  end

  def test_malformed_config_file
    write_sandbox_file('sounds.conf', "garbage content\nno = equals\n")
    assert_equal 'off', JamConfig.mode
    assert_equal 'normal', JamConfig.frequency
  end

  def test_case_insensitive_mode
    write_sandbox_file('sounds.conf', "SOUND_MODE=JAM\n")
    assert_equal 'jam', JamConfig.mode
  end

  def test_case_insensitive_key
    write_sandbox_file('sounds.conf', "sound_mode=jam\n")
    assert_equal 'jam', JamConfig.mode
  end
end
