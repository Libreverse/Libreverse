# frozen_string_literal: true
# shareable_constant_value: literal

# ActionCable permessage deflate patch
require "permessage_deflate"

module ActionCable
  module Connection
    class ClientSocket
      alias original_initialize initialize

      def initialize(env, event_target, event_loop, protocols)
        # Force maximum compression regardless of cores
        enable_deflate = true
        deflate_level = Zlib::BEST_COMPRESSION
        deflate_mem_level = Zlib::MAX_MEM_LEVEL
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
          Rails.logger.info "ActionCable permessage deflate configured (forced maximum): level=#{deflate_level}, mem_level=#{deflate_mem_level}, max_window_bits=#{deflate_max_window_bits}"
        end
      rescue StandardError => e
        Rails.logger.error "Error in ClientSocket initialization: #{e.message}"
        raise
      end
    end
  end
end
