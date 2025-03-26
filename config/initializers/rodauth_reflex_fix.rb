# frozen_string_literal: true

# This initializer handles Rodauth routing conflicts with StimulusReflex
# using a simple patch to the route recognition mechanism

# Patch ActionDispatch route recognition to handle Rodauth URLs
Rails.application.config.to_prepare do
  ActionDispatch::Routing::RouteSet.class_eval do
    alias_method :original_recognize_path, :recognize_path
    
    def recognize_path(path, environment = {})
      # Try the original implementation
      begin
        original_recognize_path(path, environment)
      rescue ActionController::RoutingError => e
        # For Rodauth URLs, return a dummy route to application#index
        if path.to_s.match?(%r{^/?(?:login|logout|create-account|password)})
          Rails.logger.debug "Rodauth route handled: #{path}"
          return { controller: "application", action: "index" }
        end
        # Re-raise for all other URLs
        raise e
      end
    end
  end
end 