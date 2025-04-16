# frozen_string_literal: true

# config/initializers/stimulus_reflex_patch.rb

=begin
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣤⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⣿⣿⣿⣿⣄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣴⣿⣿⣶⣄⠹⣿⣿⣿⡟⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡆⢹⣿⣿⣿⣷⡀⠀
⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⠀⢿⣿⣿⣿⡇⠀
⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢸⣿⣿⠟⠁⠀
⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠹⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀
⠀⠀⠀⣿⣿⣿⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⢿⣿⣿⣿⣿⡄⠀⠀⠀⠀
⠀⠀⢀⣿⣿⣿⣿⣿⡟⢀⣿⣿⣿⣿⣿⣿⡿⠟⢁⡄⠸⣿⣿⣿⣿⣷⠀⠀⠀⠀
⠀⠀⣼⣿⣿⣿⣿⠏⠀⣈⡙⠛⢛⠋⠉⠁⠀⣸⣿⣿⠀⢻⣿⣿⣿⣿⡆⠀⠀⠀
⠀⢠⣿⣿⣿⣿⣟⠀⠀⢿⣿⣿⣿⡄⠀⠀⢀⣿⣿⡟⠃⣸⣿⣿⣿⣿⡇⠀⠀⠀
⠀⠘⠛⠛⠛⠛⠛⠛⠀⠘⠛⠛⠛⠛⠓⠀⠛⠛⠛⠃⠘⠛⠛⠛⠛⠛⠃⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
patches used in this codebase.

(if you're wondering why there's ASCII art of a gorilla here,
it's a play on the term "monkey patch")
=end

# ActionCable permessage deflate patch
require "permessage_deflate"

module ActionCable
  module Connection
    class ClientSocket
      alias original_initialize initialize

      def initialize(env, event_target, event_loop, protocols)
        original_initialize(env, event_target, event_loop, protocols)
        deflate = PermessageDeflate.configure(
          level: Zlib::BEST_COMPRESSION,
          max_window_bits: 15
        )
        @driver.add_extension(deflate)
      rescue StandardError => e
        Rails.logger.error "Error in ClientSocket initialization: #{e.message}"
        raise
      end
    end
  end
end

# Grok 3 Beefed up version of my original routing patch
module RoutingPatch
    def recognize_path_with_request(request, path, options = {})
      Rails.logger.debug "[RoutingPatch] Processing path: #{path}, Request class: #{request.class}"

      # Normalize path
      original_path = path
      if path.is_a?(String) && path.start_with?("http")
        require "uri"
        uri = URI.parse(path)
        path = uri.path
        request.env["QUERY_STRING"] = uri.query if uri.query
        Rails.logger.debug "[RoutingPatch] Extracted path: #{path} from URL: #{original_path}"
      end
      path = path.sub(%r{/+\z}, "") if path.is_a?(String) # Strip trailing slashes

      # Try standard recognition
      begin
        result = super(request, path, options)
        Rails.logger.debug "[RoutingPatch] Standard recognition succeeded: #{result}"
        return result
      rescue ActionController::RoutingError => e
        Rails.logger.debug "[RoutingPatch] Standard recognition failed: #{e.message}"
      end

      # Check for Rodauth route
      begin
        if defined?(RodauthApp) && RodauthApp.rodauth # Check if Rodauth is available
          # Define the known core Rodauth paths explicitly
          known_rodauth_paths = [
            "/login",
            "/create-account",
            "/logout",
            "/remember",
            "/change-password",
            "/change-login",
            "/close-account"
          ]

          if known_rodauth_paths.include?(path)
            Rails.logger.debug "[RoutingPatch] Handling explicit Rodauth route: #{path}"

            # Set up request env
            request.env["REQUEST_PATH"] = path
            request.env["PATH_INFO"] = path
            request.env["REQUEST_URI"] = original_path # Use original path which might include query string
            request.env["HTTP_ACCEPT"] ||= "text/html"
            request.env["rack.session"] ||= {}
            request.env["action_dispatch.request.path_parameters"] ||= {}
            request.env["action_dispatch.request.path_parameters"].merge!({
                                                                            controller: "rodauth",
                                                                            action: "handle"
                                                                          })
            request.env.delete("action_dispatch.exception")

            routing_hash = { controller: "rodauth", action: "handle" }
            Rails.logger.debug "[RoutingPatch] Returning routing hash for explicit route: #{routing_hash}"
            routing_hash # Return directly
          else
            # If it's not one of the known paths, assume it's not a Rodauth route for this context
            Rails.logger.debug "[RoutingPatch] Path #{path} not in known Rodauth paths, re-raising error"
            raise ActionController::RoutingError, "No route matches \"#{original_path}\""
          end
        else
          Rails.logger.debug "[RoutingPatch] RodauthApp not defined or rodauth instance not accessible, re-raising error"
          raise ActionController::RoutingError, "No route matches \"#{original_path}\""
        end
      rescue StandardError => e # Catch errors during the check itself
        Rails.logger.error "[RoutingPatch] Unexpected error during Rodauth check: #{e.message}"
        raise ActionController::RoutingError, "Routing patch failed for \"#{original_path}\" due to internal error"
      end
    end
end

Rails.application.routes.singleton_class.prepend(RoutingPatch)
