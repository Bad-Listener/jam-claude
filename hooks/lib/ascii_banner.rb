# frozen_string_literal: true

require 'rbconfig'

# AsciiBanner - Display NBA JAM logo and activation message

module AsciiBanner
  NBA_JAM_LOGO = <<~BANNER

       ███╗   ██╗██████╗  █████╗          ██╗ █████╗ ███╗   ███╗
       ████╗  ██║██╔══██╗██╔══██╗         ██║██╔══██╗████╗ ████║
       ██╔██╗ ██║██████╔╝███████║         ██║███████║██╔████╔██║
       ██║╚██╗██║██╔══██╗██╔══██║    ██   ██║██╔══██║██║╚██╔╝██║
       ██║ ╚████║██████╔╝██║  ██║    ╚█████╔╝██║  ██║██║ ╚═╝ ██║
       ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝     ╚════╝ ╚═╝  ╚═╝╚═╝     ╚═╝

  BANNER

  class << self
    # Display the JAM Claude banner
    def display
      # Write directly to terminal, bypassing stdout (JSON) and stderr (errors)
      tty_path = RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/ ? 'CON' : '/dev/tty'
      File.open(tty_path, 'w') do |tty|
        tty.puts NBA_JAM_LOGO
        tty.puts "   🏀 BOOMSHAKALAKA! JAM MODE ACTIVATED 🏀"
        tty.puts
      end
    rescue Errno::ENODEV, Errno::ENOENT, Errno::ENXIO, Errno::EACCES
      # No terminal available (e.g., running in background or piped)
    end
  end
end
