#!/usr/bin/env ruby
# frozen_string_literal: true

# Test actual hook handlers with simulated input data

vendor_path = File.expand_path('vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)

require 'claude_hooks'
require 'json'
require_relative 'hooks/handlers/post_tool_use_handler'
require_relative 'hooks/handlers/stop_handler'

puts "Hook Handler Test\n"
puts "=" * 60

# Clean state for test
state_files = [
  File.expand_path('~/.config/claude/jam-streak.json'),
  File.expand_path('~/.config/claude/jam-error-state.json')
]

puts "\n1. Cleaning state files..."
state_files.each { |f| File.delete(f) if File.exist?(f) }
puts "   ✓ State cleaned"

# Test 1: PostToolUse handler with error
puts "\n2. Test: PostToolUse handler with permission error..."
error_input = {
  'tool_name' => 'Bash',
  'tool_response' => {
    'tool_name' => 'Bash',
    'content' => 'cat: /etc/sudoers: Permission denied',
    'is_error' => true
  }
}

begin
  handler = JamClaudePostToolUseHandler.new(error_input)
  handler.call

  # Verify error state was set
  error_state_file = File.expand_path('~/.config/claude/jam-error-state.json')
  if File.exist?(error_state_file)
    state = JSON.parse(File.read(error_state_file))
    if state['error_occurred']
      puts "   ✓ PostToolUse handler executed successfully"
      puts "   ✓ Error state set correctly"
    else
      puts "   ✗ FAILED: Error state not set"
      exit 1
    end
  else
    puts "   ✗ FAILED: Error state file not created"
    exit 1
  end
rescue StandardError => e
  puts "   ✗ FAILED: #{e.class} - #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Test 2: Stop handler checks error state and skips sound
puts "\n3. Test: Stop handler with error state..."
stop_input = {}

begin
  handler = JamClaudeStopHandler.new(stop_input)
  handler.call

  # Verify error state was cleared
  error_state_file = File.expand_path('~/.config/claude/jam-error-state.json')
  state = JSON.parse(File.read(error_state_file))

  if state['error_occurred'] == false
    puts "   ✓ Stop handler executed successfully"
    puts "   ✓ Error state cleared"
  else
    puts "   ✗ FAILED: Error state not cleared (still #{state['error_occurred']})"
    exit 1
  end
rescue StandardError => e
  puts "   ✗ FAILED: #{e.class} - #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Test 3: PostToolUse handler with success (no error)
puts "\n4. Test: PostToolUse handler with success..."
success_input = {
  'tool_name' => 'Read',
  'tool_response' => {
    'tool_name' => 'Read',
    'content' => 'File contents here',
    'is_error' => false
  }
}

begin
  handler = JamClaudePostToolUseHandler.new(success_input)
  handler.call

  # Verify error state is still false (no error)
  error_state_file = File.expand_path('~/.config/claude/jam-error-state.json')
  state = JSON.parse(File.read(error_state_file))

  if state['error_occurred'] == false
    puts "   ✓ PostToolUse handler executed successfully"
    puts "   ✓ No error state set (correct)"
  else
    puts "   ✗ FAILED: Error state incorrectly set for success"
    exit 1
  end
rescue StandardError => e
  puts "   ✗ FAILED: #{e.class} - #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Test 4: Stop handler without error state
puts "\n5. Test: Stop handler without error (normal flow)..."
stop_input = {}

begin
  handler = JamClaudeStopHandler.new(stop_input)
  handler.call

  # Verify streak was incremented
  streak_file = File.expand_path('~/.config/claude/jam-streak.json')
  if File.exist?(streak_file)
    streak_state = JSON.parse(File.read(streak_file))
    if streak_state['current_streak'] > 0
      puts "   ✓ Stop handler executed successfully"
      puts "   ✓ Streak incremented (current: #{streak_state['current_streak']})"
    else
      puts "   ✗ FAILED: Streak not incremented"
      exit 1
    end
  else
    puts "   ✗ FAILED: Streak file not created"
    exit 1
  end
rescue StandardError => e
  puts "   ✗ FAILED: #{e.class} - #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

puts "\n" + "=" * 60
puts "✓ ALL HOOK HANDLER TESTS PASSED"
puts "=" * 60

# Clean up
puts "\nCleaning up test state files..."
state_files.each { |f| File.delete(f) if File.exist?(f) }
File.delete(File.expand_path('~/.config/claude/jam-stats.json')) if File.exist?(File.expand_path('~/.config/claude/jam-stats.json'))
puts "✓ Cleanup complete"
