# frozen_string_literal: true

# ContextualCommentary Module
#
# Detects notable tool events and returns event-specific sound filenames.
# Only active in frequent mode (Tim Kitzrow Mode).
#
# Events detected:
# - Large file write (>100 lines): Monster Jam / Slams It
# - Successful test run: Scores / It's Good
# - Big edit (>20 line replacement): Razzle Dazzle
# - Code deletion (net -10+ lines): Kaboom
# - Long successful command (>50 lines output): From Downtown

module ContextualCommentary
  # Thresholds
  LARGE_WRITE_LINES = 100
  BIG_EDIT_LINES = 20
  NET_DELETION_LINES = 10
  LONG_OUTPUT_LINES = 50

  # Test runner patterns (command detection)
  TEST_COMMAND_PATTERNS = [
    /\bpytest\b/,
    /\brspec\b/,
    /\bjest\b/,
    /\bmocha\b/,
    /\bnpm\s+test\b/,
    /\byarn\s+test\b/,
    /\bgo\s+test\b/,
    /\bcargo\s+test\b/,
    /\bmake\s+test\b/,
    /\bruby\b.*_test\.rb/,
    /\bpython\b.*test/,
    /\bvitest\b/,
    /\bplaywright\b.*test/
  ].freeze

  # Test pass indicators in output
  TEST_PASS_PATTERNS = [
    /\d+\s+(passed|passing)/i,
    /\bOK\b.*\d+\s+test/i,
    /\bSUCCESS\b/,
    /Tests:\s+\d+\s+passed/i,
    /\bAll\s+\d+\s+tests?\s+passed/i,
    /\b0\s+failures?\b/i,
    /\bPASSED\b/
  ].freeze

  class << self
    # Detect a contextual event from tool usage
    # @param tool_name [String] Name of the tool
    # @param tool_input [Hash] Input passed to the tool
    # @param tool_response [Hash, String] Response from the tool
    # @return [String, nil] Sound filename or nil
    def detect(tool_name, tool_input, tool_response)
      return nil unless tool_name && tool_input

      # Skip if response indicates an error
      return nil if error_response?(tool_response)

      case tool_name
      when 'Write'
        detect_large_write(tool_input)
      when 'Edit'
        detect_edit_event(tool_input)
      when 'Bash'
        detect_bash_event(tool_input, tool_response)
      end
    end

    private

    def error_response?(tool_response)
      return true if tool_response.is_a?(Hash) && tool_response['is_error'] == true

      content = response_content(tool_response)
      content.include?('error') && content.length < 200
    end

    def response_content(tool_response)
      case tool_response
      when Hash
        tool_response['content']&.to_s || ''
      when String
        tool_response
      else
        ''
      end
    end

    # Large file write (>100 lines) → Monster Jam / Slams It
    def detect_large_write(tool_input)
      content = tool_input['content'] || tool_input[:content]
      return nil unless content.is_a?(String)

      line_count = content.count("\n") + 1
      return nil unless line_count > LARGE_WRITE_LINES

      ['Monster Jam.wav', 'Slams It.wav'].sample
    end

    # Edit events: big replacement or net deletion
    def detect_edit_event(tool_input)
      old_string = tool_input['old_string'] || tool_input[:old_string] || ''
      new_string = tool_input['new_string'] || tool_input[:new_string] || ''

      old_lines = old_string.count("\n") + 1
      new_lines = new_string.count("\n") + 1
      net_deletion = old_lines - new_lines

      # Code deletion (net -10+ lines) → Kaboom
      if net_deletion >= NET_DELETION_LINES
        return 'Kaboom.wav'
      end

      # Big edit (>20 line replacement) → Razzle Dazzle
      if old_lines > BIG_EDIT_LINES
        return 'Razzle Dazzle.wav'
      end

      nil
    end

    # Bash events: test pass or long successful command
    def detect_bash_event(tool_input, tool_response)
      command = tool_input['command'] || tool_input[:command] || ''
      content = response_content(tool_response)

      # Check for successful test run first (more specific)
      if test_command?(command) && test_passed?(content)
        return ['Scores.wav', "It's Good.wav"].sample
      end

      # Long successful command (>50 lines output, no error indicators)
      if content.count("\n") > LONG_OUTPUT_LINES && !content.match?(/error|fail|exception/i)
        return 'From Downtown.wav'
      end

      nil
    end

    def test_command?(command)
      TEST_COMMAND_PATTERNS.any? { |p| command.match?(p) }
    end

    def test_passed?(content)
      TEST_PASS_PATTERNS.any? { |p| content.match?(p) }
    end
  end
end
