# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# StimulusReflex Configuration
StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail:
  # `:exit` or `:warn` or `:ignore`
  config.on_failed_sanity_checks = :exit

  # Override the logger that the StimulusReflex uses; default is Rails' logger
  # eg. Logger.new(RAILS_ROOT + "/log/reflex.log")
  config.logger = Rails.logger

  # TruffleRuby can fail to apply StimulusReflex' refinement-based color helpers
  # (String#magenta, #green, etc.) inside the default logging proc, which raises
  # NoMethodError during Reflex message handling. Use a plain (non-colorized)
  # logging format on TruffleRuby.
  config.logging = proc do
    "[#{session_id}] #{operation_counter} #{reflex_info} -> #{selector} via #{mode} Morph (#{operation})"
  end
end
