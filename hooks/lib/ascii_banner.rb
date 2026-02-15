# frozen_string_literal: true

require 'rbconfig'
require 'json'
require_relative 'nba_facts'
require_relative 'fact_presenter'
require_relative 'fire_colors'

# AsciiBanner - Display NBA JAM logo and activation message

module AsciiBanner
  NBA_JAM_LINES = [
    '       ███╗   ██╗██████╗  █████╗          ██╗ █████╗ ███╗   ███╗',
    '       ████╗  ██║██╔══██╗██╔══██╗         ██║██╔══██╗████╗ ████║',
    '       ██╔██╗ ██║██████╔╝███████║         ██║███████║██╔████╔██║',
    '       ██║╚██╗██║██╔══██╗██╔══██║    ██   ██║██╔══██║██║╚██╔╝██║',
    '       ██║ ╚████║██████╔╝██║  ██║    ╚█████╔╝██║  ██║██║ ╚═╝ ██║',
    '       ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝     ╚════╝ ╚═╝  ╚═╝╚═╝     ╚═╝'
  ].freeze

  class << self
    # Display the JAM Claude banner
    def display
      # Write directly to terminal, bypassing stdout (JSON) and stderr (errors)
      tty_path = tty_device_path
      File.open(tty_path, 'w') do |tty|
        tty.puts
        # Gradient-colored logo: each line gets a fire color from gold → deep red
        NBA_JAM_LINES.each_with_index do |line, i|
          color = FireColors.send(FireColors::LOGO_GRADIENT[i])
          tty.puts "#{color}#{line}#{FireColors.reset}"
        end
        tty.puts
        tty.puts "         #{FireColors.gold}#{FireColors.bold}🏀 BOOMSHAKALAKA! JAM MODE ACTIVATED 🏀#{FireColors.reset}"
        version = plugin_version
        tty.puts "#{FireColors.dim_orange}#{"v#{version}".center(64)}#{FireColors.reset}" if version
        tty.puts
        result = NbaFacts.random_with_category
        tty.puts FactPresenter.format(result)
        tty.puts
      end
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES
      # No terminal available (e.g., running in background or piped)
    end

    # Display an update notification below the banner
    def display_update_notice
      return unless defined?(UpdateChecker) && UpdateChecker.update_available?

      message = UpdateChecker.update_message
      return unless message

      tty_path = tty_device_path
      File.open(tty_path, 'w') do |tty|
        tty.puts "  #{FireColors.red_orange}!#{FireColors.reset} #{message}"
        tty.puts
      end
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES
      # No terminal available
    rescue StandardError
      # Never block the session for an update notice
    end

    private

    # Read version from .claude-plugin/plugin.json
    def plugin_version
      plugin_root = ENV['CLAUDE_PLUGIN_ROOT'] || File.expand_path('../..', __dir__)
      plugin_json = File.join(plugin_root, '.claude-plugin', 'plugin.json')
      return nil unless File.exist?(plugin_json)

      data = JSON.parse(File.read(plugin_json))
      data['version']
    rescue StandardError
      nil
    end

    def tty_device_path
      RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/ ? 'CON' : '/dev/tty'
    end
  end
end
