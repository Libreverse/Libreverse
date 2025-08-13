require "active_record"
require "enhanced_sqlite3/version"
require "enhanced_sqlite3/railtie"

module EnhancedSQLite3
  Error = Class.new(StandardError)

  mattr_writer :isolate_connection_pools

  class << self
    def isolate_connection_pools?
      @isolate_connection_pools ||= @@isolate_connection_pools || false
    end
  end
end
