if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # Enable YJIT in each forked worker process
      RubyVM::YJIT.enable if defined?(RubyVM::YJIT)
      Rails.logger.info "YJIT enabled in forked worker process"
    end
  end
end