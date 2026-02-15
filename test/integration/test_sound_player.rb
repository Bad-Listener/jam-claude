# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/sound_player'

class TestSoundPlayer < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
  end

  def test_disabled_via_env_returns_true
    with_env('CLAUDE_DISABLE_SOUNDS' => '1') do
      assert_true SoundPlayer.play('any.wav')
    end
  end

  def test_disabled_when_mode_off
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\n")
    assert_true SoundPlayer.play('any.wav')
  end

  def test_missing_file_returns_false
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\n")

    # Stub spawn to avoid actually playing
    spawn_stub = stub_method(SoundPlayer, :execute_command) { true }

    result = SoundPlayer.play('nonexistent_file_xyz.wav')
    assert_false result
  end

  def test_play_weighted_empty_returns_false
    assert_false SoundPlayer.play_weighted({})
  end

  def test_play_random_empty_returns_false
    assert_false SoundPlayer.play_random([])
  end

  def test_play_calls_execute_command_for_existing_file
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\n")

    # Create a dummy sound file
    dummy_sound = File.join(@_sandbox_dir, 'test.wav')
    File.write(dummy_sound, 'fake wav data')

    # Stub the resolve path to return our dummy file
    stub_method(SoundPlayer, :resolve_sound_path) { dummy_sound }
    exec_stub = stub_method(SoundPlayer, :execute_command) { true }

    result = SoundPlayer.play('test.wav')
    assert_true result
    assert exec_stub.called?
  end

  def test_play_weighted_selects_and_plays
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\n")
    dummy_sound = File.join(@_sandbox_dir, 'sound.wav')
    File.write(dummy_sound, 'fake wav')

    stub_method(SoundPlayer, :resolve_sound_path) { dummy_sound }
    stub_method(SoundPlayer, :execute_command) { true }

    result = SoundPlayer.play_weighted({ 'sound.wav' => 1.0 })
    assert_true result
  end

  def test_platform_detection_returns_symbol
    platform = SoundPlayer.send(:detect_platform)
    assert_includes %i[macos linux windows unknown], platform
  end

  def test_macos_command_includes_afplay
    dummy_path = '/tmp/test.wav'
    command = SoundPlayer.send(:build_play_command, dummy_path)
    # On macOS (where tests run), should include afplay
    if RbConfig::CONFIG['host_os'] =~ /darwin/
      assert_match(/afplay/, command)
    end
  end
end
