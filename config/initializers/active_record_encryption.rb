# frozen_string_literal: true
# shareable_constant_value: literal

# Generate separate keys for primary and deterministic encryption
key_generator = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base, iterations: 1000
)

primary_key = key_generator.generate_key("active_record_encryption_primary", 32)
deterministic_key = key_generator.generate_key("active_record_encryption_deterministic", 32)

# Configure Active Record encryption
ActiveRecord::Encryption.configure(
  primary_key: primary_key.unpack1("H*"), # convert to hex
  deterministic_key: deterministic_key.unpack1("H*"), # use different key for deterministic encryption
  key_derivation_salt: "AR", # salt for key derivation
  support_unencrypted_data: true, # allow reading unencrypted data during migration
  encrypt_fixtures: true, # encrypt test fixtures
  store_key_references: false # don't store key references since we use deterministic keys
)
