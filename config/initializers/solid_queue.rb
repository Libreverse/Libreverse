# frozen_string_literal: true

# Use the main Rails logger (STDOUT with our custom formatter)
Rails.application.config.solid_queue.logger = Rails.logger
