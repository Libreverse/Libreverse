# CableReady Configuration
CableReady.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail options:
  # `:exit` or `:warn` or `:ignore`
  config.on_failed_sanity_checks = :exit

  # Specify a default debounce time for CableReady::Updatable callbacks
  config.updatable_debounce_time = 0.1.seconds
end
