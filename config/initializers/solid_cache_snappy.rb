# frozen_string_literal: true

require "snappy"

if defined?(SolidCache)
  module SolidCache
    module Coders
      class SnappyMarshal
        # Return raw Marshal dump (uncompressed). Allow extra args to match caller.
        def dump(value, *_args, **_kwargs)
          Marshal.dump(value)
        end

        def load(payload, *_args, **_kwargs)
          data = if defined?(Snappy)
                   begin
                     Snappy.inflate(payload)
                   rescue StandardError
                     # Fallback if payload is not snappy-compressed
                     payload
                   end
          else
                   payload
          end
          Marshal.load(data)
        end

        # Solid Cache will use this when available to store compressed bytes
        def dump_compressed(value, *args, **kwargs)
          data = dump(value, *args, **kwargs)
          defined?(Snappy) ? Snappy.deflate(data) : data
        end
      end
    end
  end

  coder = SolidCache::Coders::SnappyMarshal.new

  if SolidCache.respond_to?(:configure)
    SolidCache.configure { |c| c.default_coder = coder }
  elsif SolidCache.respond_to?(:default_coder=)
    SolidCache.default_coder = coder
  else
    Rails.application.config.after_initialize do
      Rails.cache.instance_variable_set(:@coder, coder) if defined?(ActiveSupport::Cache::SolidCacheStore) && Rails.cache.is_a?(ActiveSupport::Cache::SolidCacheStore)
    end
  end
end
