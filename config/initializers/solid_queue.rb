# frozen_string_literal: true

# Makes it log to the normal place
Rails.application.config.solid_queue.logger = ActiveSupport::Logger.new($stdout)
