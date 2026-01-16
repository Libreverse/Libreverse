# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

FriendlyId.defaults do |config|
  config.use :slugged
  # Reserve common paths to avoid conflicts
  config.use :reserved
  config.reserved_words = %w[new edit index admin dashboard]
end
