# frozen_string_literal: true
# shareable_constant_value: literal

if defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enable)
  # Optional: Only enable in production (or staging, etc.)
  # if Rails.env.production?
  RubyVM::YJIT.enable
  # end

  # Optional: Log it for confirmation
  Rails.logger.info "YJIT enabled at runtime"
end
