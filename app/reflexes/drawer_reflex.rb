# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  def toggle(args = {})
    drawer_id = args["drawer_id"] || "main"
    session_key = "drawer_expanded_#{drawer_id}".to_sym

    # Read current state from session and toggle
    current_state = session[session_key] == true
    new_state = !current_state
    session[session_key] = new_state

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
  end

  def force_update(args = {})
    drawer_id = args["drawer_id"] || "main"
    session_key = "drawer_expanded_#{drawer_id}".to_sym

    # Read current state and toggle
    current_state = session[session_key] == true
    new_state = !current_state

    # Update the session state
    session[session_key] = new_state

    # Let the default page morph handle the visual update and read from session
    # No morph :nothing here, allow default page morph
  end
end
