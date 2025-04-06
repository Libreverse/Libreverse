# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  # Sets the sidebar hover state based on the desired state passed from the client
  def set_hover_state(args = {})
      # This reflex only updates the session state so it persists between page loads
      # The actual DOM manipulation happens client-side for immediate feedback

      sidebar_id = args["sidebarId"] || "main"
      desired_state = !args["desiredState"].nil? # Force to boolean
      session_key = "sidebar_hovered_#{sidebar_id}".to_sym

      # Update the session state regardless of previous state
      session[session_key] = desired_state
      Rails.logger.info "[SidebarReflex] Updated sidebar #{sidebar_id} hover state to: #{desired_state} in session"

      # Don't do any DOM manipulation here - it's handled on the client
      morph :nothing
  rescue StandardError => e
      Rails.logger.error "[SidebarReflex] Error in set_hover_state: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      morph :nothing
  end
end
