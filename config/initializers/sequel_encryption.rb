require "active_support/key_generator"

# Derive a 32-byte key from Rails.application.secret_key_base
SEQUEL_COLUMN_ENCRYPTION_KEY = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base, iterations: 1000
).generate_key("sequel_column_encryption", 32).freeze

raise "Derived key must be 32 bytes" unless SEQUEL_COLUMN_ENCRYPTION_KEY.bytesize == 32
