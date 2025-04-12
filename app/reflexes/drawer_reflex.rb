# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  include Loggable # Assuming Loggable is available

  def toggle(args = {})
    # Use element data if available, fallback to args
    drawer_id = element&.dataset&.drawer_id || args["drawer_id"] || "main"
    # Define the UserPreference key
    key = "drawer_expanded_#{drawer_id}".to_sym

    # Ensure we have a current account (handles guests too)
    return unless current_account

    # Read current state from UserPreference and toggle
    stored_value = UserPreference.get(current_account.id, key)
    current_state = stored_value&.casecmp("true")&.zero?
    new_state = !current_state
    UserPreference.set(current_account.id, key, new_state)

    # Log the change
    log_info "Drawer '#{drawer_id}' toggled to: #{new_state} for account #{current_account.id}"

    # Define selectors
    drawer_selector = ".drawer[data-drawer-id='#{drawer_id}']"
    toggle_button_selector = "#{drawer_selector} button.drawer-toggle"
    icon_selector = "#{drawer_selector} .drawer-icons"

    if new_state
      cable_ready
        .add_css_class(selector: drawer_selector, name: "drawer-expanded")
        .set_dataset_property(selector: drawer_selector, name: "expanded", value: "true")
        .add_css_class(selector: icon_selector, name: "rotated")
        .set_attribute(selector: toggle_button_selector, name: "aria-expanded", value: "true")
        .add_css_class(selector: "body", name: "drawer-is-expanded")
    else
      cable_ready
        .remove_css_class(selector: drawer_selector, name: "drawer-expanded")
        .set_dataset_property(selector: drawer_selector, name: "expanded", value: "false")
        .remove_css_class(selector: icon_selector, name: "rotated")
        .set_attribute(selector: toggle_button_selector, name: "aria-expanded", value: "false")
        .remove_css_class(selector: "body", name: "drawer-is-expanded")
    end

    # Execute the changes
    cable_ready.broadcast

    # Use nothing morph to avoid replacing DOM elements
    morph :nothing
  rescue StandardError => e # Add basic error handling consistent with SidebarReflex
    log_error "[DrawerReflex] Error in toggle: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing # Ensure morph :nothing on error
  end

  # Removed force_update method as it relied on session and page morph
end
