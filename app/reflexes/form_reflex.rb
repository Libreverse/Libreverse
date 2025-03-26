# frozen_string_literal: true

class FormReflex < ApplicationReflex
  # Catch and log routing errors without stopping the reflex
  rescue_from ActionController::RoutingError do |exception|
    Rails.logger.warn("Routing error in FormReflex: #{exception.message}")
  end
  
  def submit
    # Get form data and ID
    form_id = element[:id]
    form_data = element.form_data || {}
    
    # Ensure we have an error container
    ensure_error_container(form_id)
    
    # Handle password validation if needed
    if form_id.to_s =~ /password/i
      validate_password_form(form_data)
    end
    
    # After validation, signal the client that form can be submitted
    cable_ready.dispatch_event(
      name: "form:validated",
      selector: "##{form_id}"
    ).broadcast
    
    # For form submission specifically, use morph :nothing
    # This allows other morphs to work normally on Rodauth pages
    # while preventing rendering conflicts just for form submission
    morph :nothing
  end
  
  private
  
  def ensure_error_container(form_id)
    return unless form_id.present?
    
    # Clear any existing errors
    cable_ready.inner_html(
      selector: "#form-errors", 
      html: ""
    ).broadcast
  end
  
  def validate_password_form(form_data)
    # Extract password fields
    password = form_data["password"] || form_data["new_password"]
    password_confirmation = form_data["password_confirmation"] || form_data["new_password_confirmation"]
    min_length = 12
    
    # Validate password
    if password.blank?
      cable_ready.inner_html(
        selector: "#form-errors", 
        html: "<div class='error'>Password is required</div>"
      ).broadcast
      return false
    end
    
    if password.to_s.length < min_length
      cable_ready.inner_html(
        selector: "#form-errors", 
        html: "<div class='error'>Password must be at least #{min_length} characters</div>"
      ).broadcast
      return false
    end
    
    if password_confirmation.present? && password.to_s != password_confirmation.to_s
      cable_ready.inner_html(
        selector: "#form-errors", 
        html: "<div class='error'>Password confirmation does not match</div>"
      ).broadcast
      return false
    end
    
    true
  end
end

