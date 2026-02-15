#!/usr/bin/env ruby
# frozen_string_literal: true

# JAM Claude Test Runner
#
# Usage:
#   ruby test/run_tests.rb              # run all tests
#   ruby test/run_tests.rb unit         # only test/unit/
#   ruby test/run_tests.rb integration  # only test/integration/
#   ruby test/run_tests.rb handler      # only test/handlers/
#   ruby test/run_tests.rb stats        # pattern match on filename

require_relative 'test_helper'

# ── Setup load paths ──────────────────────────────────────────────────────
project_root = File.expand_path('..', __dir__)
vendor_path = File.join(project_root, 'vendor', 'claude_hooks', 'lib')
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)

# ── Discover test files ───────────────────────────────────────────────────
test_dir = File.expand_path(__dir__)
pattern = ARGV[0]

# Map common aliases to directory patterns
dir_aliases = {
  'unit' => 'unit',
  'integration' => 'integration',
  'handler' => 'handlers',
  'handlers' => 'handlers'
}

test_files = if pattern && dir_aliases.key?(pattern)
               Dir.glob(File.join(test_dir, dir_aliases[pattern], 'test_*.rb')).sort
             elsif pattern
               Dir.glob(File.join(test_dir, '**', "test_*#{pattern}*.rb")).sort
             else
               Dir.glob(File.join(test_dir, '**', 'test_*.rb')).sort
             end

if test_files.empty?
  puts "No test files found#{" matching '#{pattern}'" if pattern}"
  exit 1
end

# ── Load test files ───────────────────────────────────────────────────────
test_files.each { |f| require f }

# ── Run tests ─────────────────────────────────────────────────────────────
puts "JAM Claude Test Suite"
puts "=" * 60
puts "Running #{test_files.size} test file(s)...\n\n"

total = { passed: 0, failed: 0, errors: 0, failures: [] }
start_time = Time.now

JamTest::TestCase.subclasses.each do |test_class|
  results = test_class.run_all
  total[:passed] += results[:passed]
  total[:failed] += results[:failed]
  total[:errors] += results[:errors]
  total[:failures].concat(results[:failures])
end

elapsed = Time.now - start_time

# ── Report ────────────────────────────────────────────────────────────────
puts "\n\n"
total_tests = total[:passed] + total[:failed] + total[:errors]

unless total[:failures].empty?
  puts "Failures & Errors:"
  puts "-" * 60
  total[:failures].each_with_index do |f, i|
    label = f[:type] == :failure ? 'FAIL' : 'ERROR'
    puts "\n  #{i + 1}) #{label}: #{f[:class]}##{f[:method]}"
    puts "     #{f[:message]}"
    puts "     #{f[:location]}"
  end
  puts
end

puts "=" * 60
puts "#{total_tests} tests, #{total[:passed]} passed, #{total[:failed]} failed, #{total[:errors]} errors"
puts "Finished in #{elapsed.round(3)}s"
puts "=" * 60

exit(total[:failed] + total[:errors] > 0 ? 1 : 0)
