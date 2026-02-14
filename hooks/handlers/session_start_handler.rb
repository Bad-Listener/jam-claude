# frozen_string_literal: true

require_relative '../lib/sound_player'
require_relative '../lib/ascii_banner'
require_relative '../lib/session_stats'

# JAM Claude SessionStart Handler
#
# On session start:
# - Display ASCII banner
# - Play a startup sound (weighted random)
# - Inject commentary guidelines

class JamClaudeSessionStartHandler < ClaudeHooks::SessionStart
  STARTUP_SOUNDS = {
    '28 - Welcome to NBA Jam.wav' => 0.65,
    'Hello.wav' => 0.20,
    "Tonight's Matchup.wav" => 0.15
  }.freeze

  def call
    source_type = source || 'unknown'
    log "JAM Claude: Session starting (#{source_type})"

    # Reset stats for new session
    SessionStats.reset

    # Display banner
    AsciiBanner.display

    # Kick off background update check (forks child if >24h since last check)
    UpdateChecker.check_in_background!

    # Show cached update notice from previous check (zero latency)
    AsciiBanner.display_update_notice

    # Play weighted random startup sound
    success = SoundPlayer.play_weighted(STARTUP_SOUNDS, self)
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
    context = <<~CONTEXT
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

    if UpdateChecker.update_available?
      context += <<~UPDATE

        Note: A JAM Claude update is available. If the user asks about updates or plugin status,
        let them know they can update by running:
        cd ~/.claude/plugins/jam-claude && git pull && ./install.sh
      UPDATE
    end

    context
  end
end
