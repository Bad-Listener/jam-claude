# frozen_string_literal: true

module ErrorDetector
  # Error category detection patterns
  PERMISSION_PATTERNS = [
    /permission denied/i,
    /EACCES/,
    /access forbidden/i,
    /not permitted/i,
    /unauthorized/i
  ].freeze

  FILE_NOT_FOUND_PATTERNS = [
    /no such file or directory/i,
    /ENOENT/,
    /not found/i,
    /cannot find/i,
    /does not exist/i
  ].freeze

  NETWORK_PATTERNS = [
    /connection/i,
    /timeout/i,
    /unreachable/i,
    /ECONNREFUSED/,
    /ETIMEDOUT/,
    /network/i,
    /DNS/i,
    /resolve/i
  ].freeze

  SYNTAX_PATTERNS = [
    /syntax error/i,
    /parse error/i,
    /invalid syntax/i,
    /unexpected token/i,
    /malformed/i
  ].freeze

  STATE_CORRUPTION_PATTERNS = [
    /corrupt/i,
    /invalid state/i,
    /inconsistent/i,
    /integrity/i
  ].freeze

  GENERIC_ERROR_PATTERNS = [
    /error/i,
    /failed/i,
    /failure/i,
    /exception/i,
    /fatal/i
  ].freeze

  # Detect error category from tool response
  # @param tool_response [Hash] The tool response from PostToolUse hook
  # @return [Symbol, nil] Error category symbol or nil if no error detected
  def self.detect(tool_response)
    return nil unless tool_response

    # Extract relevant fields
    content = tool_response['content']&.to_s || ''
    tool_name = tool_response['tool_name']&.to_s || ''

    # Check for explicit error indicators
    is_error = tool_response['is_error'] == true

    # For Bash tool, check exit code
    exit_code = extract_exit_code(content) if tool_name == 'Bash'

    # Return nil if no error indicators
    return nil unless is_error || exit_code&.positive? || error_in_content?(content)

    # Categorize based on exit code (Bash tool)
    if exit_code
      return categorize_by_exit_code(exit_code, content)
    end

    # Categorize based on content patterns
    categorize_by_content(content)
  end

  # Extract exit code from Bash tool output
  # @param content [String] Tool response content
  # @return [Integer, nil] Exit code or nil
  def self.extract_exit_code(content)
    # Look for exit code patterns in Bash output
    match = content.match(/exit code:?\s*(\d+)/i) || content.match(/returned (\d+)/i)
    match ? match[1].to_i : nil
  end

  # Check if content contains error indicators
  # @param content [String] Tool response content
  # @return [Boolean]
  def self.error_in_content?(content)
    GENERIC_ERROR_PATTERNS.any? { |pattern| content.match?(pattern) }
  end

  # Categorize error by exit code
  # @param exit_code [Integer] Exit code
  # @param content [String] Content for additional context
  # @return [Symbol] Error category
  def self.categorize_by_exit_code(exit_code, content)
    case exit_code
    when 127
      :command_not_found
    when 128..255
      :signal_termination
    when 126
      :permission_denied
    when 1..125
      # For generic exit failures (1-125), check content for more specific categorization
      # But avoid matching generic "error/failed" - prefer more specific patterns
      specific_category = PERMISSION_PATTERNS.any? { |p| content.match?(p) } ? :permission_denied : nil
      specific_category ||= FILE_NOT_FOUND_PATTERNS.any? { |p| content.match?(p) } ? :file_not_found : nil
      specific_category ||= NETWORK_PATTERNS.any? { |p| content.match?(p) } ? :network_error : nil
      specific_category ||= SYNTAX_PATTERNS.any? { |p| content.match?(p) } ? :syntax_error : nil
      specific_category ||= STATE_CORRUPTION_PATTERNS.any? { |p| content.match?(p) } ? :state_corruption : nil
      specific_category || :exit_failure
    else
      :exit_failure
    end
  end

  # Categorize error by content patterns
  # @param content [String] Tool response content
  # @return [Symbol, nil] Error category or nil
  def self.categorize_by_content(content)
    return :permission_denied if PERMISSION_PATTERNS.any? { |p| content.match?(p) }
    return :file_not_found if FILE_NOT_FOUND_PATTERNS.any? { |p| content.match?(p) }
    return :network_error if NETWORK_PATTERNS.any? { |p| content.match?(p) }
    return :syntax_error if SYNTAX_PATTERNS.any? { |p| content.match?(p) }
    return :state_corruption if STATE_CORRUPTION_PATTERNS.any? { |p| content.match?(p) }
    return :generic_error if GENERIC_ERROR_PATTERNS.any? { |p| content.match?(p) }

    nil
  end
end
