#!/usr/bin/env ruby
# frozen_string_literal: true

# Version bump script for JAM Claude
# Usage: ruby scripts/version-bump.rb <patch|minor|major> "<changelog entry>"
# Flags: --dry-run  Show changes without modifying files

require 'json'
require 'date'

PLUGIN_JSON = File.join(__dir__, '..', '.claude-plugin', 'plugin.json')
CHANGELOG   = File.join(__dir__, '..', 'CHANGELOG.md')

BUMP_TYPES = %w[patch minor major].freeze

def parse_args(args)
  dry_run = args.delete('--dry-run')
  bump_type = args[0]
  entry = args[1]

  unless BUMP_TYPES.include?(bump_type)
    abort "Error: First argument must be one of: #{BUMP_TYPES.join(', ')}\n" \
          "Usage: ruby scripts/version-bump.rb <patch|minor|major> \"<changelog entry>\""
  end

  if entry.nil? || entry.strip.empty?
    abort "Error: Changelog entry is required.\n" \
          "Usage: ruby scripts/version-bump.rb #{bump_type} \"<changelog entry>\""
  end

  [bump_type, entry.strip, dry_run]
end

def read_current_version
  data = JSON.parse(File.read(PLUGIN_JSON))
  data['version']
rescue Errno::ENOENT
  abort "Error: #{PLUGIN_JSON} not found. Run from the project root."
rescue JSON::ParserError
  abort "Error: #{PLUGIN_JSON} contains invalid JSON."
end

def increment_version(version, bump_type)
  parts = version.split('.').map(&:to_i)
  abort "Error: Invalid version format '#{version}'. Expected x.y.z" unless parts.length == 3

  case bump_type
  when 'major' then [parts[0] + 1, 0, 0]
  when 'minor' then [parts[0], parts[1] + 1, 0]
  when 'patch' then [parts[0], parts[1], parts[2] + 1]
  end.join('.')
end

def update_plugin_json(new_version, dry_run)
  data = JSON.parse(File.read(PLUGIN_JSON))
  data['version'] = new_version

  if dry_run
    puts "  plugin.json: version -> #{new_version}"
  else
    File.write(PLUGIN_JSON, JSON.pretty_generate(data) + "\n")
  end
end

def update_changelog(new_version, entry, dry_run)
  unless File.exist?(CHANGELOG)
    abort "Error: #{CHANGELOG} not found. Create it first."
  end

  content = File.read(CHANGELOG)
  today = Date.today.strftime('%Y-%m-%d')
  new_entry = "## [#{new_version}] - #{today}\n\n### Changed\n- #{entry}\n"

  # Insert after the header block (after the semver link line or the first blank line after header)
  marker = content.index("\n## [")
  if marker
    updated = content[0..marker] + "\n#{new_entry}\n" + content[(marker + 1)..]
  else
    # No existing entries — append after header
    updated = content.rstrip + "\n\n#{new_entry}\n"
  end

  if dry_run
    puts "  CHANGELOG.md: new entry for #{new_version}"
  else
    File.write(CHANGELOG, updated)
  end
end

# --- Main ---

bump_type, entry, dry_run = parse_args(ARGV.dup)
current = read_current_version
new_version = increment_version(current, bump_type)

if dry_run
  puts "Dry run — no files will be modified.\n\n"
end

puts "#{current} -> #{new_version} (#{bump_type})\n\n"

update_plugin_json(new_version, dry_run)
update_changelog(new_version, entry, dry_run)

if dry_run
  puts "\nRun without --dry-run to apply changes."
else
  puts "\nVersion bumped to #{new_version}."
end
