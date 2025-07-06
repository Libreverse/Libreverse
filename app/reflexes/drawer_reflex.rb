# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  include Loggable

  # Persists the drawer's expanded state from the client. Does not render or morph.
  def toggle(args = {})
    # Get drawer_id and the new expanded state directly from the arguments passed by the client.
    drawer_id = args.fetch("drawer_id") { "main" }
    new_expanded = args.fetch("expanded") { false }
    key = "drawer_expanded_#{drawer_id}"

    Rails.logger.info "[DrawerReflex#toggle] Received state for drawer '#{drawer_id}' -> expanded: #{new_expanded}"

    # Save the new state to UserPreference if the user is logged in.
    if current_account
      Rails.logger.info "[DrawerReflex#toggle] Saving new state #{new_expanded} for drawer '#{drawer_id}' to UserPreference for account #{current_account.id}"
      UserPreference.set(current_account.id, key, new_expanded)
    else
      Rails.logger.info "[DrawerReflex#toggle] No current account, skipping UserPreference save for drawer '#{drawer_id}'"
    end

    # Perform a "Nothing" morph because the client-side UI is already updated optimistically.
    morph :nothing
  rescue StandardError => e
    log_error "[DrawerReflex] Error in toggle: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing
  end
end
