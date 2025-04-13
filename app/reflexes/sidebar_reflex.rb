# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  include Loggable

  # Toggles the sidebar hover state (persists only)
  def toggle_hover
    sidebar_id = element.dataset[:sidebar_id] || "main"
    key = "sidebar_hover_enabled"

    return unless current_account

    # Read current state and toggle
    stored_value = UserPreference.get(current_account.id, key)
    current_state = stored_value == 't' || stored_value&.casecmp("true")&.zero?
    new_state = !current_state
    
    log_info "[SidebarReflex#toggle_hover] Setting hover state to: #{new_state}"
    begin
      # Store as 't' or 'f' for consistency with other preferences
      value_to_store = new_state ? 't' : 'f'
      result = UserPreference.set(current_account.id, key, value_to_store)
      log_info "[SidebarReflex#toggle_hover] UserPreference set result: #{result}"
    rescue StandardError => e
      log_error "[SidebarReflex#toggle_hover] Error setting UserPreference: #{e.message}", e
    end

    log_info "[SidebarReflex#toggle_hover] Sidebar hover toggled to: #{new_state} for account #{current_account.id} via UserPreference"

    # Determine current expanded state using the reflex's @current_account
    preference_value = @current_account ? UserPreference.get(@current_account.id, :sidebar_expanded) : nil
    current_expanded_state = (preference_value == true || preference_value == 't') # Handle boolean or 't'

    log_info "[SidebarReflex#toggle_hover] Updating sidebar DOM for ID: #{sidebar_id}"

    # First, update the sidebar container (parent element)
    render_and_morph_with_emojis(
      selector: "##{sidebar_id}-sidebar", # Target the container element
      partial: "layouts/sidebar",      # Render the main sidebar partial
      locals: { 
        sidebar_id: sidebar_id, 
        hover_enabled: new_state ? 'true' : 'false', # Send as string to match data-* attribute format
        expanded: current_expanded_state, # Pass the determined boolean state
        rodauth: controller.rodauth
      }
    )

    # Then also update the nav element to ensure both are in sync
    render_and_morph_with_emojis(
      selector: "#sidebar-nav-#{sidebar_id}", # Target the inner nav element
      partial: "layouts/sidebar_nav",      # Render the extracted nav partial
      locals: { 
        sidebar_id: sidebar_id, 
        hover_enabled: new_state ? 'true' : 'false', # Send as string to match data-* attribute format
        expanded: current_expanded_state, # Pass the determined boolean state
        rodauth: controller.rodauth
      }
    )
    
    log_debug "[SidebarReflex#toggle_hover] Broadcasting CableReady operations"
    cable_ready.broadcast
    log_info "[SidebarReflex#toggle_hover] CableReady broadcast completed"

    morph :nothing
  rescue StandardError => e
    log_error "[SidebarReflex] Error in toggle_hover: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing # Ensure we still morph nothing on error
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
