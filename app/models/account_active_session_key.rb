# Patch for Sequel direct inserts into account_active_session_keys
if defined?(Sequel)
  class AccountActiveSessionKey < Sequel::Model(:account_active_session_keys)
    def before_create
      self.created_at ||= Time.zone.now if respond_to?(:created_at) && !created_at
      self.last_use ||= Time.zone.now if respond_to?(:last_use) && !last_use
      super
    end
  end
end
