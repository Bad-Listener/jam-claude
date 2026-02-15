# frozen_string_literal: true

require_relative '../test_helper'

vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)
require 'claude_hooks'

require_relative '../../hooks/handlers/notification_handler'

class TestNotificationHandler < JamTest::TestCase
  def setup
    super
    create_sandbox

    sandbox_const(JamConfig, :CONFIG_PATH, 'sounds.conf')
    sandbox_const(SessionStats, :STATE_PATH, 'jam-stats.json')

    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=normal\n")

    @play_stub = stub_method(SoundPlayer, :play) { true }

    SessionStats.reset
  end

  def test_permission_prompt_plays_whistle
    handler = build_handler('permission_prompt')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('41 - Whistle.wav', handler)
  end

  def test_idle_prompt_plays_buzz
    handler = build_handler('idle_prompt')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('29 - Buzz1.wav', handler)
  end

  def test_elicitation_dialog_plays_horn
    handler = build_handler('elicitation_dialog')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('39 - Horn.wav', handler)
  end

  def test_unknown_type_plays_default_whistle
    handler = build_handler('unknown_type')
    handler.call

    assert @play_stub.called?
    assert @play_stub.called_with?('41 - Whistle.wav', handler)
  end

  def test_permission_prompt_increments_permissions
    handler = build_handler('permission_prompt')
    handler.call

    assert_equal 1, SessionStats.stats['permissions']
  end

  def test_idle_prompt_does_not_increment_permissions
    handler = build_handler('idle_prompt')
    handler.call

    assert_equal 0, SessionStats.stats['permissions']
  end

  def test_low_mode_skips_sound
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")

    handler = build_handler('permission_prompt')
    handler.call

    assert_false @play_stub.called?, 'Low mode should skip notification sounds'
  end

  def test_low_mode_still_tracks_permissions
    write_sandbox_file('sounds.conf', "SOUND_MODE=jam\nSOUND_FREQUENCY=low\n")

    handler = build_handler('permission_prompt')
    handler.call

    assert_equal 1, SessionStats.stats['permissions']
  end

  def test_off_mode_skips_stat_tracking
    write_sandbox_file('sounds.conf', "SOUND_MODE=off\n")

    handler = build_handler('permission_prompt')
    handler.call

    # Handler delegates sound disabling to SoundPlayer internally,
    # but stat tracking is gated on JamConfig.jam?
    assert_equal 0, SessionStats.stats['permissions']
  end

  private

  def build_handler(notification_type)
    JamClaudeNotificationHandler.new({
      'notification_type' => notification_type,
      'message' => 'Test notification'
    })
  end
end
