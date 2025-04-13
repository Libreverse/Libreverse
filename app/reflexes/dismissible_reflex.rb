# frozen_string_literal: true

class DismissibleReflex < ApplicationReflex
  include Loggable

  # Action triggered by the dismissible Stimulus controller
  def dismiss
    # Retrieve the key from the element that triggered the reflex
    # Ensure the key name matches the data attribute in the view
    key = element.dataset[:dismissible_key_value] 

    unless key.present?
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
    UserPreference.set(current_account.id, key, true)
    log_info "Marked '#{key}' as dismissed for account #{current_account.id}"

    # No DOM change needed from the server, client handles immediate hiding.
    morph :nothing 
  rescue StandardError => e
    log_error "[DismissibleReflex] Error in dismiss for key '#{key}': #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing # Ensure morph :nothing on error
  end
end
