# frozen_string_literal: true

if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked && defined?(RubyVM::YJIT)
            RubyVM::YJIT.enable
            code_size = nil
            compiled_iseqs = nil
            begin
                if RubyVM::YJIT.respond_to?(:runtime_stats)
                    stats = RubyVM::YJIT.runtime_stats
                    inline = stats[:inline_code_size] || stats["inline_code_size"] || 0
                    outlined = stats[:outlined_code_size] || stats["outlined_code_size"] || 0
                    code_size = inline + outlined
                    compiled_iseqs = stats[:compiled_iseq_count] || stats["compiled_iseq_count"]
                end
            rescue StandardError => e
                Rails.logger.debug "YJIT runtime_stats unavailable: #{e.class}: #{e.message}"
            end
            if code_size
                # YJIT code size limit from --yjit-exec-mem-size=200 (200 MB in bytes)
                yjit_code_size_limit = 200 * 1024 * 1024 # 209_715_200 bytes
                percentage = (code_size.to_f / yjit_code_size_limit * 100).round(2)
                log_message = "YJIT enabled in forked worker process - YJIT code size: #{code_size} bytes (#{percentage}% of #{yjit_code_size_limit} bytes limit)"
                log_message += " - Compiled ISeqs: #{compiled_iseqs}" if compiled_iseqs
                Rails.logger.info log_message
            else
                Rails.logger.info "YJIT enabled in forked worker process"
            end
        end
    end
end
