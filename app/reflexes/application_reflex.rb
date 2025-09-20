# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  include Loggable

  # Delegate session and authentication elements
  delegate :session, to: :request
  delegate :current_account_id, to: :connection
  # Delegate view helpers
  delegate :helpers, to: :ApplicationController

  # Add the around_reflex callback to handle :halt
  around_reflex :handle_rodauth_halt

  # Add logging callbacks
  before_reflex :log_reflex_started
  after_reflex :log_reflex_completed

  # Before reflex callback to ensure we have access to current_account
  # and set up Current attributes and I18n locale
  before_reflex :load_current_account, :set_current_attributes, :set_locale

  # Add authentication helpers for reflexes
  def authenticated?
    current_account_id.present? && !guest_account?
  end

  def guest_account?
    return false unless current_account_id

    # Use the cached account if available
    return @current_account.guest? if defined?(@current_account) && @current_account

    # Otherwise load from database
    account = Account.find(current_account_id)
    account&.guest?
  end

  # Method to ensure authentication for protected reflexes
  def require_authentication
    unless authenticated?
      log_warn "Authentication required for #{self.class.name}##{@method_name}"

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
    @current_account ||= Account.find(current_account_id)
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
  #     Current.user = current_user # Example using Current.user
  #   end
  #
  # To access view helpers inside Reflexes:
  #   delegate :helpers, to: :ApplicationController # Added delegation above
  #
  # If you need to localize your Reflexes, you can set the I18n locale here:
  #
  #   before_reflex do
  #     I18n.locale = :fr # Example setting locale
  #   end
  #
  # For code examples, considerations and caveats, see:
  # https://docs.stimulusreflex.com/guide/patterns#internationalization

  # Override morph to inject emoji replacement centrally for SR 3.x
  def morph(*args)
    args[1] = Emoji::Renderer.replace(args[1]) if args.length >= 2 && args[1].is_a?(String)
    super(*args)
  end

  private

  # Logging callbacks
  def log_reflex_started
    log_info "Started #{self.class.name}##{@method_name} reflex"
    log_debug "Reflex parameters: #{element.dataset.inspect}"
  end

  def log_reflex_completed
    log_info "Completed #{self.class.name}##{@method_name} reflex"
  end

  # Helper method to halt reflex processing in a way that works with StimulusReflex 3.5.3
  def halt_reflex
    # Use throw :abort which is the correct way to halt a reflex in StimulusReflex 3.5.3
    log_info "Halting reflex execution"
    throw :abort
  end

  # Load the current account before processing reflexes
  def load_current_account
    return unless current_account_id

      @current_account = Account.find(current_account_id)
      log_debug "Loaded account: #{current_account_id}" if @current_account
  end

  # Set Current attributes for easy access in reflexes
  def set_current_attributes
    # Assumes Current.account is defined in app/models/current.rb
    Current.account = @current_account if defined?(Current) && Current.respond_to?(:account=)
  end

  # Set I18n.locale for Reflex rendering so that translations match user preferences.
  #
  # Priority order (highest to lowest):
  #   1. Explicit user preference stored via UserPreference (if an authenticated or guest Account exists)
  #   2. Session-persisted locale, updated by e.g. LanguagePickerReflex
  #   3. Rails default locale (I18n.default_locale)
  #
  # We intentionally omit the "Accept-Language" header fallback here because
  # Reflexes are executed over ActionCable where the full Rack request is not
  # present. The header-based inference already occurred during the initial
  # HTTP request that rendered the page, so by the time a Reflex is triggered
  # the session or user preference will always reflect the client's desired
  # language.
  def set_locale
    I18n.locale =
      if current_account && (preferred = UserPreference.get(current_account.id, "locale")).present?
        preferred
      else
        session[:locale] || I18n.default_locale
      end

    log_debug "[ApplicationReflex] Locale set to: #{I18n.locale}"
  end

  def handle_rodauth_halt
    begin
      # Execute the original reflex action within a catch block for :halt
      catch(:halt) do
        yield
        return # Normal exit, no halt thrown
      end

      # If we get here, a :halt was thrown (likely by rodauth)
      log_info "Rodauth halted execution"

      # Check if we have controller and response details to use for better UX
      if controller&.response
        if controller.response.redirect?
          location = controller.response.location
          log_info "Sending redirect to: #{location}"
          cable_ready.redirect_to(url: location).broadcast
        elsif controller.response.status >= 400
          log_warn "Response status: #{controller.response.status}"
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
        log_info "No controller response, sending default redirect to login"
        cable_ready.redirect_to(url: login_path).broadcast
      end
    rescue StandardError => e
      # Catch any unexpected errors during the above processing
      log_error "Error in halt handler: #{e.message}", e

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
