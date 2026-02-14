# frozen_string_literal: true

require_relative '../../lib/jam_config'
require_relative '../lib/session_stats'

# JAM Claude PostToolUse Handler
#
# Records tool usage as basketball stats.
# Never blocks or injects context — purely passive tracking.

class JamClaudePostToolUseHandler < ClaudeHooks::PostToolUse
  def call
    if JamConfig.jam?
      SessionStats.record(tool_name)
      log "JAM Claude: Recorded #{tool_name}"
    end

    allow_continue!
    suppress_output!
    output_data
  end
end
