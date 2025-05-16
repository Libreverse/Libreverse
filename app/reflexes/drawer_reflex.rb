# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  include Loggable

  # Toggles the drawer expanded state (persists only). Fetches the current state from UserPreference.
  def toggle
    # Get the drawer_id from the element dataset, default to 'main'
    drawer_id = element.dataset[:drawer_id] || "main"
    # Construct the key matching the UserPreference ALLOWED_KEYS format
    key = "drawer_expanded_#{drawer_id}"

    # Fetch the current state from UserPreference if the user is logged in
    current_expanded = false # Default state if not logged in or preference not set
    if current_account
      # UserPreference stores 't' or 'f'
      saved_state = UserPreference.get(current_account.id, key)
      current_expanded = (saved_state == "t")
      Rails.logger.info "[DrawerReflex#toggle] Fetched current state for drawer #{drawer_id} (key '#{key}'): #{current_expanded} (from UserPreference: '#{saved_state}')"
    else
      Rails.logger.info "[DrawerReflex#toggle] No current account, assuming drawer #{drawer_id} is collapsed."
    end

    Rails.logger.info "[DrawerReflex#toggle] Using preference key: #{key}"

    # Toggle the state
    new_expanded = !current_expanded
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

      Rails.logger.error "[DrawerReflex#toggle] Verification FAILED: Mismatch between intended state (#{new_expanded}) and saved value (#{saved_value.inspect}) for key '#{key}'" unless is_saved_correctly
    else
      Rails.logger.info "[DrawerReflex#toggle] No current account, skipping UserPreference save for drawer #{drawer_id}"
    end

    # Log the value being passed to the partial
    Rails.logger.info "[DrawerReflex#toggle] Passing expanded value to partial for drawer #{drawer_id}: #{new_expanded}"

    # Add detailed logging for emoji rendering diagnostic
    Rails.logger.info "[DrawerReflex#toggle] About to call render_and_morph with drawer_id: #{drawer_id}"

    html_drawer = controller.render_to_string(partial: "layouts/drawer", locals: { drawer_id: drawer_id, expanded: new_expanded })
    morph "#main-drawer", html_drawer
    Rails.logger.info "[DrawerReflex#toggle] Drawer morph completed for drawer #{drawer_id}"
  rescue StandardError => e
    log_error "[DrawerReflex] Error in toggle: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing
  end
end
