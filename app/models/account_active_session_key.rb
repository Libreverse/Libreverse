# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Patch for Sequel direct inserts into account_active_session_keys
if defined?(Sequel)
  SessionKeyModel = Sequel::Model(:account_active_session_keys)
  # typed: ignore
  class AccountActiveSessionKey < SessionKeyModel
    def before_create
      self.created_at ||= Time.zone.now if respond_to?(:created_at) && !created_at
      self.last_use ||= Time.zone.now if respond_to?(:last_use) && !last_use
      super
    end
  end
end
