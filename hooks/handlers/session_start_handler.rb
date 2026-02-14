# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/ascii_banner'

# JAM Claude SessionStart Handler
#
# On session start:
# - Display ASCII banner
# - Play "Welcome to NBA Jam" sound
# - Inject commentary guidelines

class JamClaudeSessionStartHandler < ClaudeHooks::SessionStart
  STARTUP_SOUND = '28 - Welcome to NBA Jam.wav'

  def call
    source_type = source || 'unknown'
    log "JAM Claude: Session starting (#{source_type})"

    # Display banner
    AsciiBanner.display

    # Play welcome sound
    success = SoundPlayer.play(STARTUP_SOUND, self)
    log success ? 'JAM Claude: Played welcome sound' : 'JAM Claude: Failed to play sound',
        level: success ? :info : :warn

    # Inject commentary guidelines as additional context
    add_additional_context!(jam_context)

    allow_continue!
    suppress_output!
    output_data
  end

  private

  def jam_context
    <<~CONTEXT
      JAM Claude Mode Active 🏀

      Occasionally use these NBA Jam phrases naturally in responses:
      - "BOOMSHAKALAKA!" (after impressive solutions)
      - "He's heating up!" (building momentum on multiple tasks)
      - "From downtown!" (elegant solutions)
      - "Razzle dazzle!" (creative approaches)
      - "Is it the shoes?!" (surprising results)

      Guidelines:
      - Use sparingly (1-2 per session max)
      - Let energy emerge naturally, not forced
      - Bold the phrase: **BOOMSHAKALAKA!**
      - Only when genuinely appropriate
    CONTEXT
  end
end
