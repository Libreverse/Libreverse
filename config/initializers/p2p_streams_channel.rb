# frozen_string_literal: true
# shareable_constant_value: literal

P2pStreamsChannel.config do |config|
    # Backend-only: use Rails.cache for session store
    config.store = Rails.cache
end
