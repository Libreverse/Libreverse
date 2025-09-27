# StimulusReflex Configuration
StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail:
  # `:exit` or `:warn` or `:ignore`
  config.on_failed_sanity_checks = :exit

  # Override the logger that the StimulusReflex uses; default is Rails' logger
  # eg. Logger.new(RAILS_ROOT + "/log/reflex.log")
  config.logger = Rails.logger
end
