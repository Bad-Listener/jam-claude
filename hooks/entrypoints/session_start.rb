#!/usr/bin/env ruby
# frozen_string_literal: true

# JAM Claude - SessionStart entrypoint

# Add vendor to load path
vendor_path = File.expand_path('../../vendor/claude_hooks/lib', __dir__)
$LOAD_PATH.unshift(vendor_path) unless $LOAD_PATH.include?(vendor_path)

require 'claude_hooks'
require 'json'
require_relative '../handlers/session_start_handler'

begin
  input_data = JSON.parse($stdin.read)
  handler = JamClaudeSessionStartHandler.new(input_data)
  handler.call
  handler.output_and_exit
rescue JSON::ParserError => e
  warn "[JAM Claude SessionStart] JSON parsing error: #{e.message}"
  exit 1
rescue StandardError => e
  warn "[JAM Claude SessionStart] Error: #{e.message}"
  warn e.backtrace.join("\n") if ENV['RUBY_CLAUDE_HOOKS_DEBUG']
  exit 1
end
