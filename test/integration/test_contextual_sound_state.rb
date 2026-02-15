# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/contextual_sound_state'

class TestContextualSoundState < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(ContextualSoundState, :STATE_FILE, 'jam-contextual-state.json')
  end

  def test_mark_played_creates_file
    ContextualSoundState.mark_played!
    assert sandbox_file_exists?('jam-contextual-state.json')
  end

  def test_mark_played_sets_played_true
    ContextualSoundState.mark_played!
    state = JSON.parse(read_sandbox_file('jam-contextual-state.json'))
    assert_true state['played']
  end

  def test_played_and_clear_returns_true_when_played
    ContextualSoundState.mark_played!
    assert_true ContextualSoundState.played_and_clear?
  end

  def test_played_and_clear_clears_state
    ContextualSoundState.mark_played!
    ContextualSoundState.played_and_clear?

    state = JSON.parse(read_sandbox_file('jam-contextual-state.json'))
    assert_false state['played']
  end

  def test_played_and_clear_returns_false_when_not_played
    ContextualSoundState.clear!
    assert_false ContextualSoundState.played_and_clear?
  end

  def test_missing_file_returns_default
    state = ContextualSoundState.read_state
    assert_false state['played']
  end

  def test_corrupt_json_returns_default
    write_sandbox_file('jam-contextual-state.json', '{{invalid}')
    state = ContextualSoundState.read_state
    assert_false state['played']
  end

  def test_multiple_mark_and_clear_cycles
    3.times do
      ContextualSoundState.mark_played!
      assert_true ContextualSoundState.played_and_clear?
      assert_false ContextualSoundState.played_and_clear?
    end
  end
end
