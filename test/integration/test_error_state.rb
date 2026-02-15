# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/error_state'

class TestErrorState < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(ErrorState, :STATE_FILE, 'jam-error-state.json')
  end

  def test_mark_error_creates_file
    ErrorState.mark_error!
    assert sandbox_file_exists?('jam-error-state.json')
  end

  def test_mark_error_sets_error_occurred
    ErrorState.mark_error!
    state = JSON.parse(read_sandbox_file('jam-error-state.json'))
    assert_true state['error_occurred']
  end

  def test_error_and_clear_returns_true_when_error
    ErrorState.mark_error!
    assert_true ErrorState.error_and_clear?
  end

  def test_error_and_clear_clears_state
    ErrorState.mark_error!
    ErrorState.error_and_clear?

    state = JSON.parse(read_sandbox_file('jam-error-state.json'))
    assert_false state['error_occurred']
  end

  def test_error_and_clear_returns_false_when_no_error
    ErrorState.clear!
    assert_false ErrorState.error_and_clear?
  end

  def test_read_state_missing_file_returns_default
    state = ErrorState.read_state
    assert_false state['error_occurred']
  end

  def test_corrupt_json_returns_default
    write_sandbox_file('jam-error-state.json', 'not json {{{')
    state = ErrorState.read_state
    assert_false state['error_occurred']
  end

  def test_clear_resets_to_false
    ErrorState.mark_error!
    ErrorState.clear!
    state = ErrorState.read_state
    assert_false state['error_occurred']
  end

  def test_multiple_mark_and_clear_cycles
    3.times do
      ErrorState.mark_error!
      assert_true ErrorState.error_and_clear?
      assert_false ErrorState.error_and_clear?
    end
  end
end
