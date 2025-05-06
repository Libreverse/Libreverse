# frozen_string_literal: true

# ActionCable permessage deflate patch
require "permessage_deflate"

module ActionCable
  module Connection
    class ClientSocket
      alias original_initialize initialize

      def initialize(env, event_target, event_loop, protocols)
        original_initialize(env, event_target, event_loop, protocols)
        deflate = PermessageDeflate.configure(
          level: Zlib::BEST_COMPRESSION,
          max_window_bits: 15,
          mem_level: 9,
          no_context_takeover: true,
          strategy: Zlib::FILTERED
        )
        @driver.add_extension(deflate)
      rescue StandardError => e
        Rails.logger.error "Error in ClientSocket initialization: #{e.message}"
        raise
      end
    end
  end
end
