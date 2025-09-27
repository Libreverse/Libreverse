class DismissibleReflex < ApplicationReflex
  include Loggable

  # Action triggered by the dismissible Stimulus controller
  def dismiss
    # Retrieve the key from the element that triggered the reflex
    # Ensure the key name matches the data attribute in the view
    key = element.dataset[:dismissible_key_value]

    if key.blank?
      log_error "Dismissible key not found in element dataset: #{element.dataset.inspect}"
      return
    end

    # Ensure we have a current account (guest or logged in)
    unless current_account
      log_warn "Cannot dismiss '#{key}', current_account not found."
      return
    end

    # Use UserPreference to mark as dismissed (storing true)
    # Note: UserPreference.set handles validation and logging
    log_info "[DismissibleReflex#dismiss] Setting dismissible preference for key: #{key}"
    begin
      result = UserPreference.set(current_account.id, key, true)
      log_info "[DismissibleReflex#dismiss] UserPreference set result: #{result}"
    rescue StandardError => e
      log_error "[DismissibleReflex#dismiss] Error setting UserPreference: #{e.message}", e
      # Continue to prevent crashing the UI
    end

    log_info "[DismissibleReflex#dismiss] Marked '#{key}' as dismissed for account #{current_account.id}"

    # Always broadcast CableReady operations
    log_debug "[DismissibleReflex#dismiss] Broadcasting CableReady operations"
    cable_ready.broadcast
    log_info "[DismissibleReflex#dismiss] CableReady broadcast completed"

    # No DOM change needed from the server, client handles immediate hiding.
    morph :nothing
  rescue StandardError => e
    log_error "[DismissibleReflex] Error in dismiss for key '#{key}': #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing # Ensure morph :nothing on error
  end
end
