# frozen_string_literal: true
# shareable_constant_value: literal

# Concern for progress tracking and logging in indexers
module ProgressTrackable
  extend ActiveSupport::Concern

  private

  def log_level
    @log_level ||= begin
      level_str = global_config.fetch("log_level") { "info" }.to_s.upcase
      Logger.const_get(level_str)
    rescue NameError
      Logger::INFO
    end
  end

  def should_log?(level)
    level >= log_level
  end

  def log_debug(message, context = {})
    return unless should_log?(Logger::DEBUG)

    log_message("DEBUG", message, context)
  end

  def log_info(message, context = {})
    return unless should_log?(Logger::INFO)

    log_message("INFO", message, context)
  end

  def log_warn(message, context = {})
    return unless should_log?(Logger::WARN)

    log_message("WARN", message, context)
  end

  def log_error(message, context = {})
    return unless should_log?(Logger::ERROR)

    log_message("ERROR", message, context)
  end

  def log_message(level, message, context = {})
    log_context = {
      indexer: self.class.name,
      platform: platform_name,
      run_id: @indexing_run&.id
    }.merge(context)

    formatted_message = "[#{level}] [#{platform_name.upcase}] #{message}"
    formatted_message += " #{log_context.inspect}" if log_context.any?

    Rails.logger.send(level.downcase.to_sym, formatted_message)

    # Also broadcast progress updates for real-time monitoring
    broadcast_progress_update(level, message, log_context) if @indexing_run
  end

  def broadcast_progress_update(level, message, context)
    # Use CableReady to broadcast real-time updates to admin interface
    # Only if CableReady is available and we're in a web context
    return unless defined?(CableReady) && @indexing_run

    begin
      # Check if cable_ready method is available (requires CableReady gem and ActionCable)
      if respond_to?(:cable_ready) && cable_ready
        cable_ready["indexer_progress_#{@indexing_run.id}"].console_log(
          level: level.downcase,
          message: message,
          context: context,
          timestamp: Time.current.iso8601
        )
        cable_ready.broadcast
      end
    rescue StandardError => e
      # Don't let broadcasting errors stop indexing - just log quietly
      # Using puts instead of Rails.logger to avoid infinite recursion
      Rails.logger.debug "Failed to broadcast progress update: #{e.message}"
    end
  end

  def progress_percentage
    return 0 if @indexing_run.nil? || @total_items.nil? || @total_items.zero?

    processed = @indexing_run.items_processed
    ((processed.to_f / @total_items) * 100).round(2)
  end

  def total_items=(count)
    @total_items = count
    log_info "Total items to process: #{count}"
  end

  def total_items(count)
    self.total_items = count
  end

  def log_progress_summary
    return unless @indexing_run

    @indexing_run.duration
    processed = @indexing_run.items_processed
    failed = @indexing_run.items_failed
    success_rate = @indexing_run.success_rate

    summary = [
      "Indexing completed",
      "Duration: #{@indexing_run.duration_formatted}",
      "Processed: #{processed}",
      "Failed: #{failed}",
      "Success rate: #{success_rate}%"
    ].join(", ")

    log_info summary
  end

  def global_config
    @global_config ||= begin
      Rails.application.config_for(:indexers)["global"] || {}
    rescue StandardError
      {}
    end
  end
end
