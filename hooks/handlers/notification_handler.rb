# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/session_stats'
require_relative '../../lib/jam_config'

# JAM Claude Notification Handler
#
# Plays referee/game sounds for different notification types:
# - permission_prompt: Whistle (asking for approval)
# - idle_prompt: Buzz (shot clock running out)
# - elicitation_dialog: Horn (timeout, need input)
#
# In low mode: sounds are skipped entirely (stats still tracked)

class JamClaudeNotificationHandler < ClaudeHooks::Notification
  NOTIFICATION_SOUNDS = {
    'permission_prompt' => '41 - Whistle.wav',
    'idle_prompt' => '29 - Buzz1.wav',
    'elicitation_dialog' => '39 - Horn.wav'
  }.freeze

  DEFAULT_SOUND = '41 - Whistle.wav'

  def call
    type = notification_type || 'unknown'
    log "JAM Claude: Notification (#{type})"

    SessionStats.increment_blocks if type == 'permission_prompt' && JamConfig.jam?

    # Low mode: skip notification sounds entirely
    if JamConfig.low?
      log 'JAM Claude: Low mode — skipping notification sound'
      return output_data
    end

    sound = NOTIFICATION_SOUNDS[type] || DEFAULT_SOUND
    success = SoundPlayer.play(sound, self)

    log success ? "JAM Claude: Played #{sound}" : "JAM Claude: Failed to play #{sound}",
        level: success ? :info : :warn

    output_data
  end
end
