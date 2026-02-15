# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/update_checker'

class TestUpdateChecker < JamTest::TestCase
  def setup
    super
    create_sandbox
    sandbox_const(UpdateChecker, :STATE_PATH, 'jam-update.json')
  end

  def test_default_not_available
    assert_false UpdateChecker.update_available?
  end

  def test_update_available_from_state_file
    state = {
      'last_check_time' => Time.now.iso8601,
      'update_available' => true,
      'local_sha' => 'abc123',
      'remote_sha' => 'def456',
      'commits_behind' => 3
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    assert_true UpdateChecker.update_available?
  end

  def test_update_not_available_from_state_file
    state = {
      'last_check_time' => Time.now.iso8601,
      'update_available' => false,
      'local_sha' => 'abc123',
      'remote_sha' => 'abc123',
      'commits_behind' => 0
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    assert_false UpdateChecker.update_available?
  end

  def test_update_message_when_available
    state = {
      'last_check_time' => Time.now.iso8601,
      'update_available' => true,
      'commits_behind' => 5
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    message = UpdateChecker.update_message
    assert_not_nil message
    assert_includes message, 'Update available'
    assert_includes message, '5 commits behind'
    assert_includes message, 'git pull'
  end

  def test_update_message_single_commit
    state = {
      'last_check_time' => Time.now.iso8601,
      'update_available' => true,
      'commits_behind' => 1
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    message = UpdateChecker.update_message
    assert_includes message, '1 commit behind'
    assert !message.include?('1 commits'), 'Should not pluralize 1 commit'
  end

  def test_update_message_nil_when_not_available
    assert_nil UpdateChecker.update_message
  end

  def test_check_stale_when_never_checked
    assert_true UpdateChecker.send(:check_stale?)
  end

  def test_check_stale_when_recent
    state = {
      'last_check_time' => Time.now.iso8601,
      'update_available' => false
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    assert_false UpdateChecker.send(:check_stale?)
  end

  def test_check_stale_when_old
    old_time = (Time.now - 90_000).iso8601 # > 24 hours ago
    state = {
      'last_check_time' => old_time,
      'update_available' => false
    }
    write_sandbox_file('jam-update.json', JSON.pretty_generate(state))

    assert_true UpdateChecker.send(:check_stale?)
  end

  def test_corrupt_state_file_returns_defaults
    write_sandbox_file('jam-update.json', 'not valid json!!')

    assert_false UpdateChecker.update_available?
    assert_nil UpdateChecker.update_message
  end

  def test_git_repo_check
    # Create a fake git repo in sandbox
    git_dir = File.join(@_sandbox_dir, 'fake-repo', '.git')
    FileUtils.mkdir_p(git_dir)
    result = UpdateChecker.send(:git_repo?, File.join(@_sandbox_dir, 'fake-repo'))
    assert_true result
  end

  def test_non_git_dir
    result = UpdateChecker.send(:git_repo?, @_sandbox_dir)
    assert_false result
  end
end
