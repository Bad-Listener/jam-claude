# frozen_string_literal: true

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
      File.open('/dev/tty', 'w') do |tty|
        tty.puts NBA_JAM_LOGO
        tty.puts "   🏀 BOOMSHAKALAKA! JAM MODE ACTIVATED 🏀"
        tty.puts
      end
    rescue Errno::ENODEV, Errno::ENOENT
      # No terminal available (e.g., running in background)
    end
  end
end
