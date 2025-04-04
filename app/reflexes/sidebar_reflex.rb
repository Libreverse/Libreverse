# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  # Sets the sidebar hover state based on the desired state passed from the client
  def set_hover_state(args = {})
    if request.is_a?(ActionDispatch::Request::PASS_NOT_FOUND)
      Rails.logger.warn "Invalid request object in reflex: #{request.class}"
      return
    end

    sidebar_id = args["sidebar_id"] || "main"
    desired_state = !args["desired_state"].nil?
    session_key = "sidebar_hovered_#{sidebar_id}".to_sym

    # Read current state from session
    current_state = session[session_key] == true

    # Only proceed if the desired state is different from the current state
    if desired_state != current_state
      session[session_key] = desired_state

      # Use cable_ready operations to update specific attributes
      sidebar_selector = ".sidebar[data-sidebar-id='#{sidebar_id}']"

      if desired_state
        cable_ready
          .add_css_class(selector: sidebar_selector, name: "sidebar-hovered")
          .set_dataset_property(selector: sidebar_selector, name: "hover", value: "true")
      else
        cable_ready
          .remove_css_class(selector: sidebar_selector, name: "sidebar-hovered")
          .set_dataset_property(selector: sidebar_selector, name: "hover", value: "false")
      end

      cable_ready.broadcast
    end

    # Use nothing morph to avoid replacing DOM elements
    morph :nothing
  end

  private

  def get_inner_html_by_selector(selector)
      # Try to extract content from the DOM using cable_ready
      # This is a helper to preserve existing content

      dom_element = CableReady::DOMSelector.new(selector).to_nodes.first
      dom_element&.inner_html.to_s
  rescue StandardError
      ""
  end
end
