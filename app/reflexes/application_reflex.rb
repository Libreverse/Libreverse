# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  # Delegate current_account found by ActionCable connection - Removed
  # delegate :current_account, to: :connection

  # Ensure session is accessible from the request context within the reflex
  delegate :session, to: :request

  # Add the around_reflex callback to handle :halt
  around_reflex :handle_rodauth_halt

  # Put application-wide Reflex behavior and callbacks in this file.
  #
  # Learn more at: https://docs.stimulusreflex.com/guide/reflex-classes
  #
  # If your ActionCable connection is: `identified_by :current_user`
  #   delegate :current_user, to: :connection # Keep this if you still use :current_user elsewhere
  #
  # current_user delegation allows you to use the Current pattern, too:
  #   before_reflex do
  #     Current.user = current_user
  #   end
  #
  # To access view helpers inside Reflexes:
  #   delegate :helpers, to: :ApplicationController
  #
  # If you need to localize your Reflexes, you can set the I18n locale here:
  #
  #   before_reflex do
  #     I18n.locale = :fr
  #   end
  #
  # For code examples, considerations and caveats, see:
  # https://docs.stimulusreflex.com/guide/patterns#internationalization

  private

  def handle_rodauth_halt(&block)
    # Execute the original reflex action within a catch block for :halt
    catch(:halt, &block)

    # After the reflex action (or if it was halted), check the controller's response
    # The 'controller' object is available within the reflex context
    if controller.response.redirect?
      location = controller.response.location
      Rails.logger.info "[ApplicationReflex] Rodauth halted with redirect to: #{location}. Triggering client-side redirect via CableReady."
      # Use CableReady to instruct the client to perform the redirect
      cable_ready.redirect_to(location).broadcast
      # Prevent StimulusReflex from proceeding with its usual morphing after a halt/redirect
      prevent_controller_action
    elsif controller.response.status >= 400 && !controller.response.successful?
      # Handle other potential halt scenarios if needed (e.g., 401 Unauthorized, 403 Forbidden)
      Rails.logger.warn "[ApplicationReflex] Rodauth halted with status: #{controller.response.status}. Preventing further StimulusReflex action."
      # Optionally, you could broadcast a flash message here using CableReady
      # cable_ready.dispatch_event(name: "display:flash", detail: { message: "Unauthorized action", type: "error" }).broadcast
      prevent_controller_action
    end
    # If no :halt occurred, or if it occurred but wasn't a redirect/error we handle here,
    # StimulusReflex will continue its normal operation (e.g., morphing the DOM).
  end
end
