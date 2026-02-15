# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/contextual_commentary'

class TestContextualCommentary < JamTest::TestCase
  # ── Large write detection ──────────────────────────────────────────────
  def test_large_write_over_100_lines
    tool_input = { 'content' => "line\n" * 101 }
    tool_response = { 'content' => 'File written', 'is_error' => false }

    result = ContextualCommentary.detect('Write', tool_input, tool_response)
    assert_includes ['Monster Jam.wav', 'Slams It.wav'], result
  end

  def test_small_write_returns_nil
    tool_input = { 'content' => "line\n" * 50 }
    tool_response = { 'content' => 'File written', 'is_error' => false }

    assert_nil ContextualCommentary.detect('Write', tool_input, tool_response)
  end

  def test_write_exactly_100_lines_returns_nil
    tool_input = { 'content' => "line\n" * 99 } # 99 newlines = 100 lines
    tool_response = { 'content' => 'File written', 'is_error' => false }

    assert_nil ContextualCommentary.detect('Write', tool_input, tool_response)
  end

  # ── Big edit detection ─────────────────────────────────────────────────
  def test_big_edit_over_20_lines
    tool_input = { 'old_string' => "old\n" * 25, 'new_string' => "new\n" * 25 }
    tool_response = { 'content' => 'Edit applied', 'is_error' => false }

    assert_equal 'Razzle Dazzle.wav', ContextualCommentary.detect('Edit', tool_input, tool_response)
  end

  def test_small_edit_returns_nil
    tool_input = { 'old_string' => "old\n" * 5, 'new_string' => "new\n" * 5 }
    tool_response = { 'content' => 'Edit applied', 'is_error' => false }

    assert_nil ContextualCommentary.detect('Edit', tool_input, tool_response)
  end

  # ── Code deletion detection ────────────────────────────────────────────
  def test_net_deletion_10_lines
    tool_input = { 'old_string' => "delete\n" * 15, 'new_string' => "keep\n" * 4 }
    tool_response = { 'content' => 'Edit applied', 'is_error' => false }

    # old=16 lines, new=5 lines, net=11 → Kaboom
    assert_equal 'Kaboom.wav', ContextualCommentary.detect('Edit', tool_input, tool_response)
  end

  def test_small_deletion_returns_nil_or_razzle
    tool_input = { 'old_string' => "del\n" * 5, 'new_string' => 'keep' }
    tool_response = { 'content' => 'Edit applied', 'is_error' => false }

    # Net deletion = 5, which is < 10, so no Kaboom
    # old_lines = 6, which is < 20, so no Razzle Dazzle
    assert_nil ContextualCommentary.detect('Edit', tool_input, tool_response)
  end

  # ── Kaboom takes priority over Razzle Dazzle ───────────────────────────
  def test_deletion_priority_over_big_edit
    # 25 old lines, 5 new lines = net 20 deletion AND big edit (>20 old lines)
    tool_input = { 'old_string' => "del\n" * 24, 'new_string' => "keep\n" * 4 }
    tool_response = { 'content' => 'Edit applied', 'is_error' => false }

    assert_equal 'Kaboom.wav', ContextualCommentary.detect('Edit', tool_input, tool_response)
  end

  # ── Test pass detection ────────────────────────────────────────────────
  def test_successful_test_run
    tool_input = { 'command' => 'pytest tests/' }
    tool_response = { 'content' => '10 passed in 2.3s', 'is_error' => false }

    result = ContextualCommentary.detect('Bash', tool_input, tool_response)
    assert_includes ['Scores.wav', "It's Good.wav"], result
  end

  def test_rspec_pass
    tool_input = { 'command' => 'rspec spec/' }
    tool_response = { 'content' => '42 examples, 0 failures', 'is_error' => false }

    result = ContextualCommentary.detect('Bash', tool_input, tool_response)
    assert_includes ['Scores.wav', "It's Good.wav"], result
  end

  def test_jest_pass
    tool_input = { 'command' => 'jest --coverage' }
    tool_response = { 'content' => 'Tests: 5 passed, 5 total', 'is_error' => false }

    result = ContextualCommentary.detect('Bash', tool_input, tool_response)
    assert_includes ['Scores.wav', "It's Good.wav"], result
  end

  def test_non_test_command_not_matched
    tool_input = { 'command' => 'ls -la' }
    tool_response = { 'content' => '10 passed', 'is_error' => false }

    # Not a test command even though output looks like test results
    assert_nil ContextualCommentary.detect('Bash', tool_input, tool_response)
  end

  # ── Long output detection ──────────────────────────────────────────────
  def test_long_output_over_50_lines
    tool_input = { 'command' => 'git log' }
    tool_response = { 'content' => "commit abc\n" * 60, 'is_error' => false }

    assert_equal 'From Downtown.wav', ContextualCommentary.detect('Bash', tool_input, tool_response)
  end

  def test_long_output_with_errors_returns_nil
    tool_input = { 'command' => 'make build' }
    tool_response = { 'content' => "line\n" * 60 + 'error: something broke', 'is_error' => false }

    assert_nil ContextualCommentary.detect('Bash', tool_input, tool_response)
  end

  # ── Error responses skipped ────────────────────────────────────────────
  def test_error_response_returns_nil
    tool_input = { 'content' => "line\n" * 200 }
    tool_response = { 'content' => 'Write failed', 'is_error' => true }

    assert_nil ContextualCommentary.detect('Write', tool_input, tool_response)
  end

  # ── Nil/missing inputs ─────────────────────────────────────────────────
  def test_nil_tool_name_returns_nil
    assert_nil ContextualCommentary.detect(nil, {}, {})
  end

  def test_nil_tool_input_returns_nil
    assert_nil ContextualCommentary.detect('Write', nil, {})
  end

  # ── Unrecognized tool returns nil ──────────────────────────────────────
  def test_read_tool_returns_nil
    tool_input = { 'file_path' => '/some/file' }
    tool_response = { 'content' => 'File contents', 'is_error' => false }

    assert_nil ContextualCommentary.detect('Read', tool_input, tool_response)
  end
end
