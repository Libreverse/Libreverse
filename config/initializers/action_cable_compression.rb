# frozen_string_literal: true
# shareable_constant_value: literal

# ActionCable permessage deflate patch
require "permessage_deflate"

module ActionCable
  module Connection
    class ClientSocket
      alias original_initialize initialize

      def initialize(env, event_target, event_loop, protocols)
        # Force fast compression settings
        enable_deflate = true
        deflate_level = Zlib::BEST_SPEED
        deflate_mem_level = 1
        deflate_strategy = Zlib::DEFAULT_STRATEGY
        deflate_max_window_bits = 15
        deflate_request_max_window_bits = 15

        original_initialize(env, event_target, event_loop, protocols)
        if enable_deflate
          deflate = PermessageDeflate.configure(
            level: deflate_level,
            mem_level: deflate_mem_level,
            strategy: deflate_strategy,
            no_context_takeover: false,
            request_no_context_takeover: false,
            max_window_bits: deflate_max_window_bits,
            request_max_window_bits: deflate_request_max_window_bits
          )
          @driver.add_extension(deflate)
        end
      rescue StandardError => e
        Rails.logger.error "Error in ClientSocket initialization: #{e.message}"
        raise
      end
    end
  end
end
