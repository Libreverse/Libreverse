# Authentication Configuration
# This file contains all authentication-related configurations including:
# - Rodauth base configuration
# - Rodauth routing fixes for StimulusReflex

# ===== Rodauth Base Configuration =====
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end

# ===== Rodauth Routing Fix for StimulusReflex =====
# This patch handles Rodauth routing conflicts with StimulusReflex
# using a simple patch to the route recognition mechanism
Rails.application.config.to_prepare do
  ActionDispatch::Routing::RouteSet.class_eval do
    alias_method :original_recognize_path, :recognize_path

    def recognize_path(path, environment = {})
        # For StimulusReflex requests, ignore query parameters for routing
        if environment["HTTP_X_STIMULUS_REFLEX"].present?
          path_without_params = path.to_s.split("?").first
          environment[:path_without_params] = path_without_params

          # Special handling for search page reflexes
          return { controller: "search", action: "index" } if path_without_params == "/search"
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
