# frozen_string_literal: true

# ActionCable permessage deflate patch
require "permessage_deflate"

# Dynamic configuration based on CPU cores
cores = ThreadBudget.total_threads

if cores < 8
  # Disable compression on low-core systems to save CPU
  enable_deflate = false
  Rails.logger.info "ActionCable permessage deflate disabled (cores: #{cores} < 8)"
elsif cores < 16
  # Balance compression and CPU on mid-core systems
  enable_deflate = true
  deflate_level = Zlib::DEFAULT_COMPRESSION
  deflate_mem_level = 6
  deflate_strategy = Zlib::DEFAULT_STRATEGY
  deflate_max_window_bits = 13
  deflate_request_max_window_bits = 13
else
  # Maximize compression on high-core systems
  enable_deflate = true
  deflate_level = Zlib::BEST_COMPRESSION
  deflate_mem_level = Zlib::MAX_MEM_LEVEL
  deflate_strategy = Zlib::DEFAULT_STRATEGY
  deflate_max_window_bits = 15
  deflate_request_max_window_bits = 15
end

if enable_deflate
  Rails.logger.info "ActionCable permessage deflate configured for #{cores} cores: level=#{deflate_level}, mem_level=#{deflate_mem_level}, max_window_bits=#{deflate_max_window_bits}"
end

module ActionCable
  module Connection
    class ClientSocket
      alias original_initialize initialize

      def initialize(env, event_target, event_loop, protocols)
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
