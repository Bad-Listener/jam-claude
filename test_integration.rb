#!/usr/bin/env ruby
# frozen_string_literal: true

# Integration test - simulates the full hook flow

vendor_path = File.expand_path('vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)

require 'claude_hooks'
require 'json'
require 'fileutils'

# Load all modules
require_relative 'hooks/lib/error_detector'
require_relative 'hooks/lib/error_sound_mapper'
require_relative 'hooks/lib/error_state'
require_relative 'hooks/lib/sound_player'
require_relative 'hooks/lib/streak_tracker'
require_relative 'hooks/lib/session_stats'
require_relative 'lib/jam_config'

puts "Integration Test: Error Commentary Flow\n"
puts "=" * 60

# Clean state files for test
state_files = [
  File.expand_path('~/.config/claude/jam-streak.json'),
  File.expand_path('~/.config/claude/jam-error-state.json'),
  File.expand_path('~/.config/claude/jam-stats.json')
]

puts "\n1. Cleaning state files..."
state_files.each do |file|
  File.delete(file) if File.exist?(file)
end
puts "   ✓ State files cleaned"

# Initialize state
puts "\n2. Initializing fresh state..."
StreakTracker.increment # Start at 1
SessionStats.record('Bash')
puts "   Streak: #{StreakTracker.current_streak}"
puts "   Stats: #{SessionStats.stats['points']} points"
puts "   ✓ Initial state created"

# Test 1: Error occurs - should reset streak
puts "\n3. Test: Tool error (permission denied)..."
error_response = {
  'tool_name' => 'Bash',
  'content' => 'cat: /etc/sudoers: Permission denied',
  'is_error' => true
}

error_category = ErrorDetector.detect(error_response)
puts "   Detected error: #{error_category}"

if error_category
  # Simulate PostToolUse handler behavior
  sound_file = ErrorSoundMapper.select_sound(error_category)
  puts "   Selected sound: #{sound_file}"

  # Play sound (non-blocking)
  puts "   Playing error sound..."
  # SoundPlayer.play(sound_file) # Commented out to avoid actual sound during test

  # Reset streak
  StreakTracker.reset
  puts "   Streak after error: #{StreakTracker.current_streak}"

  # Mark error state
  ErrorState.mark_error!
  puts "   Error state marked"

  # Increment turnovers
  SessionStats.increment_turnovers
  puts "   Turnovers: #{SessionStats.stats['turnovers']}"

  puts "   ✓ Error handled correctly"
else
  puts "   ✗ FAILED: Error not detected"
  exit 1
end

# Test 2: Stop hook checks error state
puts "\n4. Test: Stop hook with error state..."
error_occurred = ErrorState.error_and_clear?
puts "   Error flag: #{error_occurred}"

if error_occurred
  puts "   ✓ Stop hook would skip success sound (correct)"
else
  puts "   ✗ FAILED: Error flag not set"
  exit 1
end

# Verify error state is cleared
error_still_set = ErrorState.read_state['error_occurred']
if error_still_set
  puts "   ✗ FAILED: Error state not cleared"
  exit 1
else
  puts "   ✓ Error state cleared after Stop hook"
end

# Test 3: Success after error - streak should restart
puts "\n5. Test: Success after error (streak restart)..."
StreakTracker.increment
streak_after_success = StreakTracker.current_streak
puts "   Streak after success: #{streak_after_success}"

if streak_after_success == 1
  puts "   ✓ Streak restarted correctly"
else
  puts "   ✗ FAILED: Streak should be 1, got #{streak_after_success}"
  exit 1
end

# Test 4: Multiple successes build streak
puts "\n6. Test: Multiple successes build streak..."
StreakTracker.increment # 2
StreakTracker.increment # 3
final_streak = StreakTracker.current_streak
puts "   Final streak: #{final_streak}"

if final_streak == 3
  puts "   ✓ Streak increments correctly"
else
  puts "   ✗ FAILED: Expected streak 3, got #{final_streak}"
  exit 1
end

# Verify final state
puts "\n7. Verifying final state files..."
final_stats = SessionStats.stats
puts "   Points: #{final_stats['points']}"
puts "   Turnovers: #{final_stats['turnovers']}"
puts "   Peak Streak: #{final_stats['peak_streak']}"

expected_turnovers = 1
if final_stats['turnovers'] == expected_turnovers
  puts "   ✓ Turnovers tracked correctly"
else
  puts "   ✗ FAILED: Expected #{expected_turnovers} turnover, got #{final_stats['turnovers']}"
  exit 1
end

puts "\n" + "=" * 60
puts "✓ ALL INTEGRATION TESTS PASSED"
puts "=" * 60

# Clean up test state files
puts "\nCleaning up test state files..."
state_files.each do |file|
  File.delete(file) if File.exist?(file)
end
puts "✓ Cleanup complete"
