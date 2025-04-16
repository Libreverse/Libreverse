# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  include Loggable

  # Toggles the drawer expanded state (persists only)
  # Expects the current expanded state ('true' or 'false' string) as an argument.
  def toggle(current_expanded_str = "false")
    # Get the drawer_id from the element dataset, default to 'main'
    drawer_id = element.dataset[:drawer_id] || "main"
    # Construct the key matching the UserPreference ALLOWED_KEYS format
    key = "drawer_expanded_#{drawer_id}"

    # Convert the passed string argument to a boolean
    # Default to false if the argument is missing or not 'true'
    expanded = current_expanded_str == "true"

    Rails.logger.info "[DrawerReflex#toggle] Received current state for drawer #{drawer_id}: #{expanded} (from client argument: '#{current_expanded_str}')"
    Rails.logger.info "[DrawerReflex#toggle] Using preference key: #{key}"

    # Toggle the state
    new_expanded = !expanded
    Rails.logger.info "[DrawerReflex#toggle] Toggling state for drawer #{drawer_id} to: #{new_expanded}"

    # Save the new state to UserPreference if the user is logged in
    if current_account
      Rails.logger.info "[DrawerReflex#toggle] Saving new state #{new_expanded} for drawer #{drawer_id} to UserPreference for account #{current_account.id}"
      # Debug the save operation more thoroughly
      begin
        result = UserPreference.set(current_account.id, key, new_expanded)
        Rails.logger.info "[DrawerReflex#toggle] UserPreference.set result for key '#{key}': #{result.inspect}"
      rescue StandardError => e
        Rails.logger.error "[DrawerReflex#toggle] Error saving to UserPreference: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
      # Verify the saved value
      saved_value = UserPreference.get(current_account.id, key)
      Rails.logger.info "[DrawerReflex#toggle] Verified saved value for drawer #{drawer_id} (key '#{key}') in UserPreference: #{saved_value.inspect}"

      # Correctly compare the boolean state with the stored string ('t'/'f')
      is_saved_correctly = (new_expanded && saved_value == "t") || (!new_expanded && saved_value == "f")

      unless is_saved_correctly
        Rails.logger.error "[DrawerReflex#toggle] Verification FAILED: Mismatch between intended state (#{new_expanded}) and saved value (#{saved_value.inspect}) for key '#{key}'"
      end
    else
      Rails.logger.info "[DrawerReflex#toggle] No current account, skipping UserPreference save for drawer #{drawer_id}"
    end

    # Log the value being passed to the partial
    Rails.logger.info "[DrawerReflex#toggle] Passing expanded value to partial for drawer #{drawer_id}: #{new_expanded}"

    # Add detailed logging for emoji rendering diagnostic
    Rails.logger.info "[DrawerReflex#toggle] About to call render_and_morph_with_emojis with drawer_id: #{drawer_id}"

    # Use the helper from ApplicationReflex to render, process emojis, and morph
    render_and_morph_with_emojis(
      selector: "#main-drawer", # Target selector for the drawer
      partial: "layouts/drawer", # Path to the drawer partial
      locals: { drawer_id: drawer_id, expanded: new_expanded }
    )

    Rails.logger.info "[DrawerReflex#toggle] render_and_morph_with_emojis completed for drawer #{drawer_id}"

    # Broadcast the queued CableReady operations without accessing internal arrays
    cable_ready.broadcast
    Rails.logger.info "[DrawerReflex#toggle] CableReady broadcast completed for drawer #{drawer_id}"

    # Ensure we don't do a full page refresh (keep the original morph mode)
    morph :nothing
  rescue StandardError => e
    log_error "[DrawerReflex] Error in toggle: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing
  end
end
