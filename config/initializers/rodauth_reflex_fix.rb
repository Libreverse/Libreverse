# frozen_string_literal: true

# This initializer handles Rodauth routing conflicts with StimulusReflex
# using a simple patch to the route recognition mechanism

# Patch ActionDispatch route recognition to handle Rodauth URLs
Rails.application.config.to_prepare do
  ActionDispatch::Routing::RouteSet.class_eval do
    alias_method :original_recognize_path, :recognize_path

    def recognize_path(path, environment = {})
        # For StimulusReflex requests, ignore query parameters for routing
        if environment["HTTP_X_STIMULUS_REFLEX"].present?
          path_without_params = path.to_s.split('?').first
          environment[:path_without_params] = path_without_params
          
          # Special handling for search page reflexes
          if path_without_params == "/search"
            return { controller: "search", action: "index" }
          end
        end
        
        # Try the original implementation
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
