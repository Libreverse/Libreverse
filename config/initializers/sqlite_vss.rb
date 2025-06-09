# frozen_string_literal: true

# Load sqlite-vss extension for vector search capabilities
Rails.application.config.to_prepare do
  # We only want to try loading VSS in environments that use SQLite and where it makes sense.
  # Adjust this condition if you use SQLite in other environments like test (though often mocked).
  if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter) && \
     (Rails.env.development? || Rails.env.production?)

    # The core idea is to ensure that every new SQLite connection gets the VSS extension loaded.
    # ActiveRecord connection pooling means connections are reused, but new ones can be created.

    ActiveRecord::ConnectionAdapters::SQLite3Adapter.set_callback :checkout do |connection|
      # This block is called when a connection is checked out from the pool.
      # We use a flag on the connection itself to avoid redundant load attempts on the same connection.
      unless connection.instance_variable_get(:@vss_loaded)
        begin
          raw_connection = connection.raw_connection
          raw_connection.enable_load_extension(true)
          require "sqlite_vss" unless defined?(SqliteVss)
          SqliteVss.load(raw_connection)
          raw_connection.enable_load_extension(false)
          connection.instance_variable_set(:@vss_loaded, true)
          Rails.logger.info "VSS extension successfully loaded for connection: #{connection.object_id}"
        rescue StandardError => e
          connection.instance_variable_set(:@vss_loaded, false) # Mark as failed for this connection
          Rails.logger.warn "Failed to load VSS extension for connection: #{connection.object_id}. Error: #{e.message}"
          # Depending on how critical VSS is, you might want to raise an error here
          # or allow the application to continue with VSS potentially unavailable for this connection.
        end
      end
    end

    # Attempt to load VSS for any existing connections immediately upon initialization.
    # This helps if connections were established before this initializer ran fully.
    begin
      if ActiveRecord::Base.connected?
        conn = ActiveRecord::Base.connection
        # Manually trigger the checkout logic if the callback hasn't run for this connection yet.
        # This is a bit of a heuristic; the callback should handle new checkouts.
        unless conn.instance_variable_get(:@vss_loaded)
          raw_conn = conn.raw_connection
          raw_conn.enable_load_extension(true)
          require "sqlite_vss" unless defined?(SqliteVss)
          SqliteVss.load(raw_conn)
          raw_conn.enable_load_extension(false)
          conn.instance_variable_set(:@vss_loaded, true)
          Rails.logger.info "VSS extension successfully loaded for existing initial connection: #{conn.object_id}"
        end
      end
    rescue StandardError => e
      Rails.logger.warn "Failed to load VSS for initial active connection: #{e.message}"
    end

    # Add a helper to the adapter to check availability if needed elsewhere.
    module VssAvailabilityChecker
      def vss_available?
        # Check the flag set by the :checkout callback.
        # If the flag is nil (never attempted) or false (attempted and failed),
        # it implies VSS might not be loaded for this specific connection.
        # A true value means it was successfully loaded at least once for this connection.
        !!instance_variable_get(:@vss_loaded)
      end
    end
    ActiveRecord::ConnectionAdapters::SQLite3Adapter.include VssAvailabilityChecker

  end
end
