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
      $stderr.puts NBA_JAM_LOGO
      $stderr.puts "   🏀 BOOMSHAKALAKA! JAM MODE ACTIVATED 🏀"
      $stderr.puts
    end
  end
end
