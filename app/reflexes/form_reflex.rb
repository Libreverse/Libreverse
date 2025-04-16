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

    # Validate the form - will set error messages if invalid
    @validation_errors = []
    if validate_form(form_data)
      # After validation, signal the client that form can be submitted
      log_info "[FormReflex#submit] Form validated successfully, dispatching form:validated event"
      cable_ready.dispatch_event(
        name: "form:validated",
        selector: "##{form_id}"
      )
      cable_ready.broadcast
      log_info "[FormReflex#submit] CableReady broadcast completed"

      # Use render_and_morph_with_emojis to update the error container
      render_and_morph_with_emojis(
        selector: "#form-errors",
        partial: "layouts/form_errors",
        locals: { errors: [] }
      )
    else
      log_info "[FormReflex#submit] Form validation failed with #{@validation_errors.length} errors"
      # Use render_and_morph_with_emojis to show error messages
      render_and_morph_with_emojis(
        selector: "#form-errors",
        partial: "layouts/form_errors",
        locals: { errors: @validation_errors }
      )
    end
  rescue StandardError => e
    log_error "[FormReflex#submit] Error processing form: #{e.message}", e
    log_error e.backtrace.join("\n")

    # Show error in form
    @validation_errors ||= []
    @validation_errors << "An error occurred processing the form"
    render_and_morph_with_emojis(
      selector: "#form-errors",
      partial: "layouts/form_errors",
      locals: { errors: @validation_errors }
    )
  end

  private

  def validate_form(form_data)
    valid = true

    # Basic validation for required fields
    form_data.each do |field_name, value|
      # Skip hidden fields and submit buttons
      next if /^(_method|authenticity_token|commit)$/.match?(field_name.to_s)

      # Check if the field is required (would need actual field metadata here)
      # For now, we assume if a field has "required" in the name, it's required
      if field_name.to_s =~ /required/ && value.to_s.strip.empty?
        valid = false
        @validation_errors << "#{field_name.to_s.humanize} is required"
      end

      # Validate email fields
      if field_name.to_s =~ /email/ && !value.to_s.strip.empty? && value.to_s !~ /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
          valid = false
          @validation_errors << "Email format is invalid"
      end

      # Validate password fields
      if validate_password_field?(field_name)
        # Delegate to the password validator
        valid = validate_password_form(form_data) && valid
      end
    end

    valid
  end

  def validate_password_field?(field_name)
    field_name.to_s =~ /password/i
  end

  def validate_password_form(form_data)
    # Extract password fields
    password = form_data["password"] || form_data["new_password"]
    password_confirmation = form_data["password_confirmation"] || form_data["new_password_confirmation"]
    min_length = 12

    # Validate password
    if password.blank?
      @validation_errors << "Password is required"
      return false
    end

    if password.to_s.length < min_length
      @validation_errors << "Password must be at least #{min_length} characters"
      return false
    end

    if password_confirmation.present? && password.to_s != password_confirmation.to_s
      @validation_errors << "Password confirmation does not match"
      return false
    end

    true
  end
end
