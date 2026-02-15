# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/error_detector'

class TestErrorDetector < JamTest::TestCase
  # ── Permission denied ───────────────────────────────────────────────────
  def test_permission_denied_from_content
    response = { 'content' => 'Permission denied', 'is_error' => true }
    assert_equal :permission_denied, ErrorDetector.detect(response)
  end

  def test_permission_denied_eacces
    response = { 'content' => 'EACCES error', 'is_error' => true }
    assert_equal :permission_denied, ErrorDetector.detect(response)
  end

  def test_permission_denied_exit_126
    response = { 'tool_name' => 'Bash', 'content' => 'exit code: 126', 'is_error' => true }
    assert_equal :permission_denied, ErrorDetector.detect(response)
  end

  # ── File not found ──────────────────────────────────────────────────────
  def test_file_not_found
    response = { 'content' => 'No such file or directory', 'is_error' => true }
    assert_equal :file_not_found, ErrorDetector.detect(response)
  end

  def test_file_not_found_enoent
    response = { 'content' => 'ENOENT: file missing', 'is_error' => true }
    assert_equal :file_not_found, ErrorDetector.detect(response)
  end

  # ── Exit failure ────────────────────────────────────────────────────────
  def test_exit_failure_code_1
    response = { 'tool_name' => 'Bash', 'content' => 'Command failed with exit code: 1', 'is_error' => true }
    assert_equal :exit_failure, ErrorDetector.detect(response)
  end

  def test_exit_failure_code_2
    response = { 'tool_name' => 'Bash', 'content' => 'exit code: 2', 'is_error' => true }
    assert_equal :exit_failure, ErrorDetector.detect(response)
  end

  # ── Command not found ──────────────────────────────────────────────────
  def test_command_not_found_exit_127
    response = { 'tool_name' => 'Bash', 'content' => 'command not found, exit code: 127', 'is_error' => true }
    assert_equal :command_not_found, ErrorDetector.detect(response)
  end

  # ── Signal termination ─────────────────────────────────────────────────
  def test_signal_termination_exit_130
    response = { 'tool_name' => 'Bash', 'content' => 'exit code: 130', 'is_error' => true }
    assert_equal :signal_termination, ErrorDetector.detect(response)
  end

  def test_signal_termination_exit_137
    response = { 'tool_name' => 'Bash', 'content' => 'exit code: 137', 'is_error' => true }
    assert_equal :signal_termination, ErrorDetector.detect(response)
  end

  def test_signal_termination_exit_255
    response = { 'tool_name' => 'Bash', 'content' => 'exit code: 255', 'is_error' => true }
    assert_equal :signal_termination, ErrorDetector.detect(response)
  end

  # ── Network error ───────────────────────────────────────────────────────
  def test_network_error
    response = { 'content' => 'Could not resolve host: nonexistent.domain', 'is_error' => true }
    assert_equal :network_error, ErrorDetector.detect(response)
  end

  def test_network_error_econnrefused
    response = { 'content' => 'ECONNREFUSED', 'is_error' => true }
    assert_equal :network_error, ErrorDetector.detect(response)
  end

  # ── Syntax error ────────────────────────────────────────────────────────
  def test_syntax_error
    response = { 'content' => 'SyntaxError: Unexpected token', 'is_error' => true }
    assert_equal :syntax_error, ErrorDetector.detect(response)
  end

  def test_parse_error
    response = { 'content' => 'parse error near line 42', 'is_error' => true }
    assert_equal :syntax_error, ErrorDetector.detect(response)
  end

  # ── State corruption ───────────────────────────────────────────────────
  def test_state_corruption
    response = { 'content' => 'File is corrupt', 'is_error' => true }
    assert_equal :state_corruption, ErrorDetector.detect(response)
  end

  def test_integrity_error
    response = { 'content' => 'integrity check failed', 'is_error' => true }
    assert_equal :state_corruption, ErrorDetector.detect(response)
  end

  # ── Generic error ───────────────────────────────────────────────────────
  def test_generic_error_fallback
    response = { 'content' => 'Something failed unexpectedly', 'is_error' => true }
    assert_equal :generic_error, ErrorDetector.detect(response)
  end

  # ── No error ────────────────────────────────────────────────────────────
  def test_success_returns_nil
    response = { 'content' => 'hello world', 'is_error' => false }
    assert_nil ErrorDetector.detect(response)
  end

  def test_nil_response_returns_nil
    assert_nil ErrorDetector.detect(nil)
  end

  def test_empty_content_no_error_flag
    response = { 'content' => '', 'is_error' => false }
    assert_nil ErrorDetector.detect(response)
  end

  # ── Exit code with content override ─────────────────────────────────────
  def test_exit_code_1_with_permission_content
    response = { 'tool_name' => 'Bash', 'content' => 'Permission denied, exit code: 1', 'is_error' => true }
    assert_equal :permission_denied, ErrorDetector.detect(response)
  end

  def test_exit_code_1_with_network_content
    response = { 'tool_name' => 'Bash', 'content' => 'connection refused, exit code: 1', 'is_error' => true }
    assert_equal :network_error, ErrorDetector.detect(response)
  end
end
