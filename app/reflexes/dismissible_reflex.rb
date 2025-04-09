# frozen_string_literal: true

class DismissibleReflex < ApplicationReflex
  # Handles dismissible elements by storing the dismissed state in the session
  # The element triggering the reflex is passed automatically by StimulusReflex
  def dismiss
    # Get the key from the element's data attribute
    # Note: Stimulus controller passes the element via stimulate
    key = element.dataset[:dismissible_key_value]

    # Debug information
    Rails.logger.info "DismissibleReflex#dismiss called for element with key: '#{key}'"

    if key.present?
      # Store in session that this item has been dismissed
      session[:dismissed_items] ||= []
      session[:dismissed_items] << key unless session[:dismissed_items].include?(key)
      Rails.logger.info "Updated session[:dismissed_items]: #{session[:dismissed_items].inspect}"

      # If this is a preference that should be stored in database and the user is authenticated
      if UserPreference::ALLOWED_KEYS.include?(key) && authenticated?
        # Persist this preference to the database for the logged-in user
        UserPreference.dismiss(current_account_id, key)
        Rails.logger.info "Stored dismissal in database for account: #{current_account_id}, key: #{key}"
      elsif UserPreference::ALLOWED_KEYS.include?(key) && guest_account?
        # Store preference for guest account temporarily
        UserPreference.dismiss(current_account_id, key)
        Rails.logger.info "Stored dismissal for guest account: #{current_account_id}, key: #{key}"
      else
        Rails.logger.info "Storing dismissal in session only (no account or not allowed key) for key: #{key}"
      end

      # Just signal success without changing DOM - the element is already hidden in the controller
      morph :nothing
    else
      Rails.logger.error "Dismissible Reflex: No key found for element"
      Rails.logger.error "Available data: #{element.dataset.inspect}"
    end
  end

  private

  # Simple DOM ID helper
  def dom_id(element)
    # Try to get id, or generate one
    element.id.presence || "dismissible-#{SecureRandom.hex(4)}"
  end
end
