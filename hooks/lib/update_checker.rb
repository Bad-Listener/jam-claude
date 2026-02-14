# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require 'open3'

# UpdateChecker - Background update detection for JAM Claude
#
# State file: ~/.config/claude/jam-update.json
# Checks at most once per 24 hours via background fork.
# The *current* session reads cached state from the *previous* check,
# so there is zero latency impact on startup.
#
# Usage:
#   UpdateChecker.check_in_background!  # fork + git fetch (if stale)
#   UpdateChecker.update_available?     # reads cached state (fast)
#   UpdateChecker.update_message        # formatted string or nil

class UpdateChecker
  STATE_PATH = File.expand_path('~/.config/claude/jam-update.json')
  CHECK_INTERVAL = 86_400 # 24 hours in seconds
  FETCH_TIMEOUT = 30 # seconds

  class << self
    # Fork a child to run git fetch and compare SHAs.
    # Returns immediately in the parent. No-ops if checked recently.
    def check_in_background!
      return unless check_stale?

      repo_dir = plugin_repo_dir
      return unless git_repo?(repo_dir)

      fork_and_check(repo_dir)
    rescue NotImplementedError
      # Windows/JRuby — fork not available; silently skip
    rescue StandardError
      # Never block the session
    end

    # Read cached state — was an update detected on the last check?
    def update_available?
      load_state['update_available'] == true
    rescue StandardError
      false
    end

    # Formatted notification string, or nil if no update.
    def update_message
      state = load_state
      return nil unless state['update_available']

      behind = state['commits_behind'].to_i
      behind_text = behind > 0 ? " (#{behind} commit#{'s' if behind != 1} behind)" : ''
      "Update available#{behind_text}. Run: cd ~/.claude/plugins/jam-claude && git pull && ./install.sh"
    rescue StandardError
      nil
    end

    private

    # True if we haven't checked in the last CHECK_INTERVAL seconds.
    def check_stale?
      state = load_state
      last = state['last_check_time']
      return true if last.nil?

      elapsed = Time.now - Time.parse(last)
      elapsed >= CHECK_INTERVAL
    rescue StandardError
      true
    end

    # Path to the plugin source repo (the git clone, not the cache).
    def plugin_repo_dir
      ENV['CLAUDE_PLUGIN_ROOT'] || File.expand_path('../..', __dir__)
    end

    # Quick check: is the directory a git repo?
    def git_repo?(dir)
      File.directory?(File.join(dir, '.git'))
    end

    # Fork a child process to do the slow network work.
    def fork_and_check(repo_dir)
      pid = fork do
        perform_check(repo_dir)
      end
      Process.detach(pid) if pid
    end

    # Runs inside the forked child.
    def perform_check(repo_dir)
      require 'timeout'

      # Fetch latest from origin with timeout guard
      Timeout.timeout(FETCH_TIMEOUT) do
        system('git', '-C', repo_dir, 'fetch', 'origin', 'main', '--quiet',
               [:out, :err] => File::NULL)
      end

      local_sha  = git_rev(repo_dir, 'HEAD')
      remote_sha = git_rev(repo_dir, 'origin/main')

      return if local_sha.nil? || remote_sha.nil?

      behind = commits_behind(repo_dir, local_sha, remote_sha)

      save_state(
        'last_check_time' => Time.now.iso8601,
        'update_available' => local_sha != remote_sha,
        'local_sha' => local_sha,
        'remote_sha' => remote_sha,
        'commits_behind' => behind
      )
    rescue Timeout::Error, StandardError
      # Swallow all errors in the child — never surface to user
    end

    # Resolve a git ref to a SHA using safe array-form execution.
    def git_rev(repo_dir, ref)
      out, status = Open3.capture2('git', '-C', repo_dir, 'rev-parse', ref,
                                   :err => File::NULL)
      return nil unless status.success?

      sha = out.strip
      sha.empty? ? nil : sha
    rescue StandardError
      nil
    end

    # Count commits local is behind remote.
    def commits_behind(repo_dir, local_sha, remote_sha)
      return 0 if local_sha == remote_sha

      out, status = Open3.capture2('git', '-C', repo_dir, 'rev-list', '--count',
                                   "#{local_sha}..#{remote_sha}",
                                   :err => File::NULL)
      status.success? ? out.strip.to_i : 0
    rescue StandardError
      0
    end

    # Load cached state from JSON.
    def load_state
      return default_state unless File.exist?(STATE_PATH)

      JSON.parse(File.read(STATE_PATH))
    rescue JSON::ParserError, StandardError
      default_state
    end

    # Atomic write: PID-specific temp file + rename.
    def save_state(state)
      FileUtils.mkdir_p(File.dirname(STATE_PATH))

      temp_path = "#{STATE_PATH}.#{Process.pid}.tmp"
      File.write(temp_path, JSON.pretty_generate(state))
      File.rename(temp_path, STATE_PATH)
    rescue StandardError
      # Best-effort — don't crash the child
      FileUtils.rm_f(temp_path) if temp_path
    end

    def default_state
      {
        'last_check_time' => nil,
        'update_available' => false,
        'local_sha' => nil,
        'remote_sha' => nil,
        'commits_behind' => 0
      }
    end
  end
end
