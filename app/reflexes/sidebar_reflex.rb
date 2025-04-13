# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  include Loggable

  # Toggles the sidebar hover state (persists only)
  def toggle_hover
    sidebar_id = element.dataset[:sidebar_id] || "main"
    key = :sidebar_hover_enabled

    return unless current_account

    # Read current state and toggle
    stored_value = UserPreference.get(current_account.id, key)
    current_state = stored_value&.casecmp("true")&.zero?
    new_state = !current_state
    UserPreference.set(current_account.id, key, new_state)

    log_info "Sidebar hover toggled to: #{new_state} for account #{current_account.id} via UserPreference"

    # No explicit DOM update needed here; rely on data-reflex-root morph
    # morph :nothing
  rescue StandardError => e
    log_error "[SidebarReflex] Error in toggle_hover: #{e.message}", e
    log_error e.backtrace.join("\n")
    # morph :nothing
  end

  # Optional: Add set_expanded_state if explicit toggle needed later
  # def set_expanded_state(expanded)
  #   # ... logic ...
  #   update_sidebar_dom(sidebar_id: "main", expanded: new_state, hover_enabled: current_sidebar_hover_state)
  #   morph :nothing
  # end

  # REMOVED: current_sidebar_expanded_state method (if helper handles this)
  # REMOVED: update_sidebar_dom method
end
