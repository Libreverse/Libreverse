# frozen_string_literal: true

if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked
            if defined?(RubyVM::YJIT)
                RubyVM::YJIT.enable
                code_size = nil
                begin
                    if RubyVM::YJIT.respond_to?(:runtime_stats)
                        stats    = RubyVM::YJIT.runtime_stats
                        inline   = stats[:inline_code_size] || stats['inline_code_size'] || 0
                        outlined = stats[:outlined_code_size] || stats['outlined_code_size'] || 0
                        code_size = inline + outlined
                    end
                rescue => e
                    Rails.logger.debug "YJIT runtime_stats unavailable: #{e.class}: #{e.message}"
                end

                if code_size
                    Rails.logger.info "YJIT enabled in forked worker process - YJIT code size: #{code_size} bytes"
                else
                    Rails.logger.info "YJIT enabled in forked worker process"
                end
            end
        end
    end
end
