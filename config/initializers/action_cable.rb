# frozen_string_literal: true

=begin
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣤⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⣿⣿⣿⣿⣄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣴⣿⣿⣶⣄⠹⣿⣿⣿⡟⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡆⢹⣿⣿⣿⣷⡀⠀
⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⠀⢿⣿⣿⣿⡇⠀
⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢸⣿⣿⠟⠁⠀
⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠹⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀
⠀⠀⠀⣿⣿⣿⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⢿⣿⣿⣿⣿⡄⠀⠀⠀⠀
⠀⠀⢀⣿⣿⣿⣿⣿⡟⢀⣿⣿⣿⣿⣿⣿⡿⠟⢁⡄⠸⣿⣿⣿⣿⣷⠀⠀⠀⠀
⠀⠀⣼⣿⣿⣿⣿⠏⠀⣈⡙⠛⢛⠋⠉⠁⠀⣸⣿⣿⠀⢻⣿⣿⣿⣿⡆⠀⠀⠀
⠀⢠⣿⣿⣿⣿⣟⠀⠀⢿⣿⣿⣿⡄⠀⠀⢀⣿⣿⡟⠃⣸⣿⣿⣿⣿⡇⠀⠀⠀
⠀⠘⠛⠛⠛⠛⠛⠛⠀⠘⠛⠛⠛⠛⠓⠀⠛⠛⠛⠃⠘⠛⠛⠛⠛⠛⠃⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
patch to action cable⠀to support compression.

(if you're wondering why there's ASCII art of a gorilla here,
it's a play on the term "monkey patch")

P.S. I know this is an egregious hack, but it improves performance so
much that I can't not use it.
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
=end

require "permessage_deflate"

module ActionCable
  module Connection
    class ClientSocket
      alias_method :original_initialize, :initialize

      def initialize(env, event_target, event_loop, protocols)
        Rails.logger.debug "Initializing ClientSocket with env: #{env.inspect}"
        original_initialize(env, event_target, event_loop, protocols)
        deflate = PermessageDeflate.configure(
          level: Zlib::BEST_COMPRESSION,
          max_window_bits: 15
        )
        @driver.add_extension(deflate)
        Rails.logger.debug "PerMessageDeflate extension added."
      rescue => e
        Rails.logger.error "Error in ClientSocket initialization: #{e.message}"
        raise
      end
    end
  end
end
