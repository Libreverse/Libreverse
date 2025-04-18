# frozen_string_literal: true

# CableReady Configuration
CableReady.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail options:
  # `:exit` or `:warn` or `:ignore`
  config.on_failed_sanity_checks = :exit

  # Enable/disable assets compilation
  # config.precompile_assets = true

  # Define your own custom operations
  # https://cableready.stimulusreflex.com/customization#custom-operations
  # config.add_operation_name :jazz_hands

  # Change the default Active Job queue used for broadcast_later and broadcast_later_to
  # config.broadcast_job_queue = :default

  # Specify a default debounce time for CableReady::Updatable callbacks
  config.updatable_debounce_time = 0.1.seconds
end
