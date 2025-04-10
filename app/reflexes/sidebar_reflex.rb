# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  # Toggles the sidebar hover state and updates the DOM via CableReady
  def toggle_hover(args = {})
    sidebar_id = args["sidebar_id"] || "main" # Match drawer arg name
    session_key = "sidebar_hovered_#{sidebar_id}".to_sym

    # Read current state from session and toggle
    current_state = session[session_key] == true
    new_state = !current_state
    session[session_key] = new_state

    Rails.logger.info "[SidebarReflex] Toggled sidebar #{sidebar_id} hover state to: #{new_state} in session"

    # Define selectors (assuming similar structure to drawer for hover state)
    sidebar_selector = ".sidebar[data-sidebar-id='#{sidebar_id}']"
    # Assuming a toggle element exists, though hover might not need an explicit button
    # toggle_button_selector = "#{sidebar_selector} button.sidebar-toggle"
    # Assuming icons exist that might change appearance on hover
    # icon_selector = "#{sidebar_selector} .sidebar-icons"

    if new_state
      cable_ready
        .add_css_class(selector: sidebar_selector, name: "sidebar-hovered") # Class to indicate hover state
        .set_dataset_property(selector: sidebar_selector, name: "hovered", value: "true")
        # Example: Add class to body if needed when sidebar is hovered
        .add_css_class(selector: "body", name: "sidebar-is-hovered")
        # Example: Update aria-expanded if relevant for accessibility
        # .set_attribute(selector: toggle_button_selector, name: "aria-expanded", value: "true")
        # Example: Rotate icons if applicable
        # .add_css_class(selector: icon_selector, name: "rotated")
    else
      cable_ready
        .remove_css_class(selector: sidebar_selector, name: "sidebar-hovered")
        .set_dataset_property(selector: sidebar_selector, name: "hovered", value: "false")
        .remove_css_class(selector: "body", name: "sidebar-is-hovered")
        # .set_attribute(selector: toggle_button_selector, name: "aria-expanded", value: "false")
        # .remove_css_class(selector: icon_selector, name: "rotated")
    end

    # Execute the changes
    cable_ready.broadcast

    # Use nothing morph to avoid replacing DOM elements unnecessarily
    morph :nothing
  rescue StandardError => e
      Rails.logger.error "[SidebarReflex] Error in toggle_hover: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Ensure morph :nothing is called even on error to prevent unexpected page morphs
      morph :nothing
  end

  # Optional: If a full page morph based on session state is ever needed,
  # you could add a method similar to DrawerReflex#force_update.
  # def force_update(args = {})
  #   sidebar_id = args["sidebar_id"] || "main"
  #   session_key = "sidebar_hovered_#{sidebar_id}".to_sym
  #   current_state = session[session_key] == true
  #   new_state = !current_state
  #   session[session_key] = new_state
  #   # Allow default page morph by not calling morph :nothing
  # end
end
