# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  # Delegate session and authentication elements
  delegate :session, to: :request
  delegate :current_account_id, to: :connection

  # Add the around_reflex callback to handle :halt
  around_reflex :handle_rodauth_halt

  # Before reflex callback to ensure we have access to current_account
  before_reflex :load_current_account

  # Add authentication helpers for reflexes
  def authenticated?
    current_account_id.present? && !guest_account?
  end

  def guest_account?
    return false unless current_account_id

    # Use the cached account if available
    return @current_account.guest? if defined?(@current_account) && @current_account

    # Otherwise load from database
    account = Account.find_by(id: current_account_id)
    account&.guest?
  end

  # Method to ensure authentication for protected reflexes
  def require_authentication
    unless authenticated?
      Rails.logger.warn "[ApplicationReflex] Authentication required for #{self.class.name}##{@method_name}"

      # Use CableReady to instruct the client to redirect to login page
      cable_ready.redirect_to(url: login_path).broadcast
      # Prevent the reflex from continuing
      halt_reflex

      # Return false so calling methods can use this as a guard
      return false
    end

    true
  end

  # Helper to access the current account
  def current_account
    @current_account ||= Account.find_by(id: current_account_id)
  end

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

  # Helper method to halt reflex processing in a way that works with StimulusReflex 3.5.3
  def halt_reflex
    # Use throw :abort which is the correct way to halt a reflex in StimulusReflex 3.5.3
    throw :abort
  end

  # Load the current account before processing reflexes
  def load_current_account
    @current_account = Account.find_by(id: current_account_id) if current_account_id
  end

  def handle_rodauth_halt
    begin
      # Execute the original reflex action within a catch block for :halt
      catch(:halt) do
        yield
        return # Normal exit, no halt thrown
      end

      # If we get here, a :halt was thrown (likely by rodauth)
      Rails.logger.info "[ApplicationReflex] Rodauth halted execution"

      # Check if we have controller and response details to use for better UX
      if controller&.response
        if controller.response.redirect?
          location = controller.response.location
          Rails.logger.info "[ApplicationReflex] Sending redirect to: #{location}"
          cable_ready.redirect_to(url: location).broadcast
        elsif controller.response.status >= 400
          Rails.logger.warn "[ApplicationReflex] Response status: #{controller.response.status}"
          cable_ready.dispatch_event(
            name: "display:flash",
            detail: {
              message: "Authentication required for this action",
              type: "error"
            }
          ).broadcast
        end
      else
        # Default behavior - redirect to login
        Rails.logger.info "[ApplicationReflex] No controller response, sending default redirect to login"
        cable_ready.redirect_to(url: login_path).broadcast
      end
    rescue StandardError => e
      # Catch any unexpected errors during the above processing
      Rails.logger.error "[ApplicationReflex] Error in halt handler: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Try to send a message to the client
      begin
        cable_ready.dispatch_event(
          name: "display:flash",
          detail: {
            message: "An error occurred",
            type: "error"
          }
        ).broadcast
      rescue StandardError
        # Last-ditch effort - if even that fails, just continue
      end
    end

    # Always halt the reflex after a Rodauth halt
    halt_reflex
  end

  # Helper to get the login path - works with or without route helpers
  def login_path
    defined?(login_path) ? login_path : "/login"
  end
end
