#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for error detection and sound mapping

require_relative 'hooks/lib/error_detector'
require_relative 'hooks/lib/error_sound_mapper'

# Test cases
test_cases = [
  {
    name: 'Permission Denied',
    response: {
      'tool_name' => 'Bash',
      'content' => 'cat: /etc/sudoers: Permission denied',
      'is_error' => true
    },
    expected_category: :permission_denied,
    expected_sound: 'Rejected.wav'
  },
  {
    name: 'File Not Found',
    response: {
      'tool_name' => 'Read',
      'content' => 'Error: No such file or directory - /nonexistent/file.txt',
      'is_error' => true
    },
    expected_category: :file_not_found,
    expected_sound: '54 - Off the rim.wav'
  },
  {
    name: 'Exit Code 1 (Generic Failure)',
    response: {
      'tool_name' => 'Bash',
      'content' => 'Command failed with exit code: 1',
      'is_error' => true
    },
    expected_category: :exit_failure,
    expected_sound: ['Terrible Shot.wav', 'No Good.wav'] # Either is valid (weighted random)
  },
  {
    name: 'Command Not Found (Exit 127)',
    response: {
      'tool_name' => 'Bash',
      'content' => 'nonexistentcommand: command not found, exit code: 127',
      'is_error' => true
    },
    expected_category: :command_not_found,
    expected_sound: 'Wild Shot.wav'
  },
  {
    name: 'Network Error',
    response: {
      'tool_name' => 'Bash',
      'content' => 'curl: (6) Could not resolve host: nonexistent.domain.invalid',
      'is_error' => true
    },
    expected_category: :network_error,
    expected_sound: 'Intercepted.wav'
  },
  {
    name: 'Syntax Error',
    response: {
      'tool_name' => 'Bash',
      'content' => 'SyntaxError: Unexpected token in JSON at position 42',
      'is_error' => true
    },
    expected_category: :syntax_error,
    expected_sound: 'Ugly Shot.wav'
  },
  {
    name: 'Signal Termination (Exit 130)',
    response: {
      'tool_name' => 'Bash',
      'content' => 'Process terminated with exit code: 130',
      'is_error' => true
    },
    expected_category: :signal_termination,
    expected_sound: '53 - Shove.wav'
  },
  {
    name: 'No Error (Success)',
    response: {
      'tool_name' => 'Bash',
      'content' => 'hello world',
      'is_error' => false
    },
    expected_category: nil,
    expected_sound: nil
  }
]

puts "Testing Error Detection and Sound Mapping\n"
puts "=" * 60

passed = 0
failed = 0

test_cases.each do |test|
  puts "\nTest: #{test[:name]}"
  puts "-" * 60

  # Detect error category
  detected = ErrorDetector.detect(test[:response])

  # Check category
  category_match = detected == test[:expected_category]
  puts "Category: #{detected.inspect} (expected: #{test[:expected_category].inspect})"
  puts category_match ? "✓ Category match" : "✗ Category mismatch"

  # Check sound mapping (if error detected)
  if detected
    sound = ErrorSoundMapper.select_sound(detected)

    if test[:expected_sound].is_a?(Array)
      sound_match = test[:expected_sound].include?(sound)
      puts "Sound: #{sound} (expected one of: #{test[:expected_sound].join(', ')})"
    else
      sound_match = sound == test[:expected_sound]
      puts "Sound: #{sound} (expected: #{test[:expected_sound]})"
    end

    puts sound_match ? "✓ Sound match" : "✗ Sound mismatch"

    if category_match && sound_match
      passed += 1
      puts "✓ PASSED"
    else
      failed += 1
      puts "✗ FAILED"
    end
  elsif test[:expected_category].nil?
    passed += 1
    puts "✓ PASSED (no error, as expected)"
  else
    failed += 1
    puts "✗ FAILED (expected error, got none)"
  end
end

puts "\n" + "=" * 60
puts "Results: #{passed} passed, #{failed} failed"
puts "=" * 60

exit(failed > 0 ? 1 : 0)
