# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  include Loggable

  # Toggles the sidebar hover state (persists only)
  def toggle_hover
    sidebar_id = element.dataset[:sidebar_id] || "main"
    key = "sidebar_hovered"

    return unless current_account

    # Read current state and toggle
    stored_value = UserPreference.get(current_account.id, key)
    current_state = stored_value == "t" || stored_value&.casecmp("true")&.zero?
    new_state = !current_state

    log_info "[SidebarReflex#toggle_hover] Setting hover state to: #{new_state}"
    begin
      # Store as 't' or 'f' for consistency with other preferences
      value_to_store = new_state ? "t" : "f"
      result = UserPreference.set(current_account.id, key, value_to_store)
      log_info "[SidebarReflex#toggle_hover] UserPreference set result: #{result}"
    rescue StandardError => e
      log_error "[SidebarReflex#toggle_hover] Error setting UserPreference: #{e.message}", e
    end

    log_info "[SidebarReflex#toggle_hover] Sidebar hover toggled to: #{new_state} for account #{current_account.id} via UserPreference"

    log_info "[SidebarReflex#toggle_hover] Updating sidebar DOM for ID: #{sidebar_id}, new hover state: #{new_state}"

    begin
      if new_state
        # Add hover classes
        cable_ready.add_css_class selector: "##{sidebar_id}-sidebar", name: "sidebar-hovered"
        cable_ready.add_css_class selector: "#sidebar-nav-#{sidebar_id}", name: "sidebar-hovered"
      else
        # Remove hover classes
        cable_ready.remove_css_class selector: "##{sidebar_id}-sidebar", name: "sidebar-hovered"
        cable_ready.remove_css_class selector: "#sidebar-nav-#{sidebar_id}", name: "sidebar-hovered"
      end

      # Update attributes so future page loads/stimulus see correct values
      hover_attr_value = new_state ? "true" : "false"
      cable_ready.set_attribute selector: "##{sidebar_id}-sidebar", name: "data-hovered", value: hover_attr_value
      cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "data-hovered", value: hover_attr_value

      cable_ready.broadcast
    rescue StandardError => e
      log_error "[SidebarReflex#toggle_hover] CableReady error: #{e.message}", e
    end

    morph :nothing
  rescue StandardError => e
    log_error "[SidebarReflex] Error in toggle_hover: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing # Ensure we still morph nothing on error
  end

  # ---------------------------------------------------------------------------
  # NEW: Explicitly set the hover (expanded) state based on a boolean argument.
  # This avoids repeatedly toggling the state when the sidebar element is
  # re-rendered, which previously caused an infinite loop of mouseenter and
  # mouseleave events. Instead of morphing the entire sidebar/nav elements we
  # use CableReady operations to add or remove the `sidebar-hovered` class and
  # keep aria / data attributes in sync. This updates the DOM in place so the
  # browser does not fire additional hover events.
  # ---------------------------------------------------------------------------
  # rubocop:disable Naming/AccessorMethodName
  def set_hover_state(hovered)
    sidebar_id = element.dataset["sidebar_id"] || "main"

    # Cast the incoming param to a proper boolean in a way that supports the
    # JavaScript truthy/falsey values we might receive.
    hovered_bool = ActiveModel::Type::Boolean.new.cast(hovered)

    # Persist the hover state for logged-in users so that the next page
    # render reflects the correct expanded/collapsed state.
    if current_account
      begin
        UserPreference.set(current_account.id, "sidebar_hovered", hovered_bool ? "t" : "f")
      rescue StandardError => e
        log_error "[SidebarReflex#set_hover_state] Error persisting hover state: #{e.message}", e
      end
    end

    begin
      if hovered_bool
        cable_ready.add_css_class selector: "##{sidebar_id}-sidebar", name: "sidebar-hovered"
        cable_ready.add_css_class selector: "#sidebar-nav-#{sidebar_id}", name: "sidebar-hovered"

        # Keep both legacy and value-style attributes in sync
        cable_ready.set_attribute selector: "##{sidebar_id}-sidebar", name: "data-expanded", value: "true"
        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "data-expanded", value: "true"

        cable_ready.set_attribute selector: "##{sidebar_id}-sidebar", name: "data-expanded-value", value: "true"
        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "data-expanded-value", value: "true"

        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "aria-expanded", value: "true"
      else
        cable_ready.remove_css_class selector: "##{sidebar_id}-sidebar", name: "sidebar-hovered"
        cable_ready.remove_css_class selector: "#sidebar-nav-#{sidebar_id}", name: "sidebar-hovered"

        # Keep both legacy and value-style attributes in sync
        cable_ready.set_attribute selector: "##{sidebar_id}-sidebar", name: "data-expanded", value: "false"
        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "data-expanded", value: "false"

        cable_ready.set_attribute selector: "##{sidebar_id}-sidebar", name: "data-expanded-value", value: "false"
        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "data-expanded-value", value: "false"

        cable_ready.set_attribute selector: "#sidebar-nav-#{sidebar_id}", name: "aria-expanded", value: "false"
      end

      cable_ready.broadcast
      morph :nothing
    rescue StandardError => e
      log_error "[SidebarReflex#set_hover_state] Error: #{e.message}", e
      morph :nothing
    end
  end
  # rubocop:enable Naming/AccessorMethodName

  # Optional: Add set_expanded_state if explicit toggle needed later
  # def set_expanded_state(expanded)
  #   # ... logic ...
  #   update_sidebar_dom(sidebar_id: "main", expanded: new_state, hover_enabled: current_sidebar_hover_state)
  #   morph :nothing
  # end

  # REMOVED: current_sidebar_expanded_state method (if helper handles this)
  # REMOVED: update_sidebar_dom method
end
