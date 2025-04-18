# frozen_string_literal: true

# RoutingPatch for handling custom Rodauth routes
module RoutingPatch
  def recognize_path_with_request(request, path, options = {})
    Rails.logger.debug "[RoutingPatch] Processing path: #{path}, Request class: #{request.class}"

    original_path = path
    if path.is_a?(String) && path.start_with?("http")
      require "uri"
      uri = URI.parse(path)
      path = uri.path
      request.env["QUERY_STRING"] = uri.query if uri.query
      Rails.logger.debug "[RoutingPatch] Extracted path: #{path} from URL: #{original_path}"
    end

    path = path.sub(%r{/+\z}, "") if path.is_a?(String)

    begin
      result = super(request, path, options)
      Rails.logger.debug "[RoutingPatch] Standard recognition succeeded: #{result}"
      return result
    rescue ActionController::RoutingError => e
      Rails.logger.debug "[RoutingPatch] Standard recognition failed: #{e.message}"
    end

    begin
      if defined?(RodauthApp) && RodauthApp.rodauth
        known_rodauth_paths = [ "/login", "/create-account", "/logout", "/remember", "/change-password", "/change-login", "/close-account" ]
        if known_rodauth_paths.include?(path)
          Rails.logger.debug "[RoutingPatch] Handling explicit Rodauth route: #{path}"
          request.env["REQUEST_PATH"] = path
          request.env["PATH_INFO"] = path
          request.env["REQUEST_URI"] = original_path
          request.env["HTTP_ACCEPT"] ||= "text/html"
          request.env["rack.session"] ||= {}
          request.env["action_dispatch.request.path_parameters"] ||= {}
          request.env["action_dispatch.request.path_parameters"].merge!(controller: "rodauth", action: "handle")
          request.env.delete("action_dispatch.exception")

          routing_hash = { controller: "rodauth", action: "handle" }
          Rails.logger.debug "[RoutingPatch] Returning routing hash for explicit route: \\#{routing_hash}"
          routing_hash
        else
          Rails.logger.debug "[RoutingPatch] Path #{path} not in known Rodauth paths, re-raising error"
          raise ActionController::RoutingError, "No route matches \"#{original_path}\""
        end
      else
        Rails.logger.debug "[RoutingPatch] RodauthApp not defined or rodauth instance not accessible, re-raising error"
        raise ActionController::RoutingError, "No route matches \"#{original_path}\""
      end
    rescue StandardError => e
      Rails.logger.error "[RoutingPatch] Unexpected error during Rodauth check: #{e.message}"
      raise ActionController::RoutingError, "Routing patch failed for \"#{original_path}\" due to internal error"
    end
  end
end

Rails.application.routes.singleton_class.prepend(RoutingPatch)
