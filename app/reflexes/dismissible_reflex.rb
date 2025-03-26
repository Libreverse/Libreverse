# frozen_string_literal: true

class DismissibleReflex < ApplicationReflex
  # Handles dismissible elements by storing the dismissed state in the session
  def dismiss(key = nil)
    # Get the key from the parameter or from the element's data attribute as fallback
    key ||= element.dataset[:dismissible_key_value]

    # Debug information
    Rails.logger.info "DismissibleReflex#dismiss called with key: '#{key}'"

    if key.present?
      # Store in session that this item has been dismissed
      session[:dismissed_items] ||= []
      session[:dismissed_items] << key unless session[:dismissed_items].include?(key)
      Rails.logger.info "Updated session[:dismissed_items]: #{session[:dismissed_items].inspect}"

      # Get the current account ID from session
      account_id = session[:account_id]

      # Store in the database if possible
      if UserPreference::ALLOWED_KEYS.include?(key) && account_id.present?
        UserPreference.dismiss(account_id, key)
        Rails.logger.info "Stored dismissal in database for account: #{account_id}, key: #{key}"
      else
        Rails.logger.info "Storing dismissal in session only (no account) for key: #{key}"
      end

      # Just signal success without changing DOM - the element is already hidden in the controller
      morph :nothing
    else
      Rails.logger.error "Dismissible Reflex: No key found for element"
      Rails.logger.error "Available data: #{element.dataset.inspect}"
    end
  end

  private

  # Helper to access current_account
  def current_account
    @current_account ||= Account.find_by(id: session[:account_id])
  end

  # Simple DOM ID helper
  def dom_id(element)
    # Try to get id, or generate one
    element.id.presence || "dismissible-#{SecureRandom.hex(4)}"
  end
end
