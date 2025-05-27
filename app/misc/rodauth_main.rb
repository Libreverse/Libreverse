# frozen_string_literal: true

require_relative "../models/account"
require_relative "../services/moderation_service"
require "rodauth/model"
require "sequel/core"

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    enable :create_account,
           :login, :logout, :remember,
           :change_password, :change_login,
           :close_account,
           :argon2, :pwned_password,
           :guest, # anonymous auth
           :internal_request,
           :i18n

    rails_account_model AccountSequel

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> Guest Feature Configuration
    # Generate guest logins as UUIDs instead of email-like strings
    new_guest_login { SecureRandom.uuid }

    # Set guest account flag on creation
    before_create_guest do
      account[:guest] = true
      # Set timestamps for guest accounts to prevent database constraint violations
      now = Time.current
      account[:created_at] = now
      account[:updated_at] = now
    end

    # Transfer user preferences from guest account to new account when registered
    before_delete_guest do
      # session_value has the guest account ID
      # account_id has the new account ID
      guest_account_id = session_value
      new_account_id = account_id

      # Transfer preferences from guest account to the new account
      UserPreference.where(account_id: guest_account_id).find_each do |preference|
        # Only transfer if the new account doesn't already have this preference
        UserPreference.set(new_account_id, preference.key, preference.value) unless UserPreference.exists?(
          account_id: new_account_id, key: preference.key
        )
      end

      # After transferring preferences, delete all preferences for the guest account
      # to avoid foreign key constraint violation when deleting the guest account
      UserPreference.where(account_id: guest_account_id).destroy_all
    end

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.sqlite(extensions: :activerecord_connection, keep_reference: false)
    # Avoid DB query that checks accounts table schema at boot time.
    convert_token_id_to_integer? { Account.columns_hash["id"].type == :integer }

    # Change prefix of table and foreign key column names from default "account"
    # accounts_table :users
    # verify_account_table :user_verification_keys
    # verify_login_change_table :user_login_change_keys
    # reset_password_table :user_password_reset_keys
    # remember_table :user_remember_keys

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    hmac_secret Rails.application.secret_key_base

    # Use a rotatable password pepper when hashing passwords with Argon2.
    argon2_secret Rails.application.secret_key_base
    # Argon2 costs left at gem defaults; see config/initializers/argon2.rb if custom costs are needed.

    # Since we're using argon2, prevent loading the bcrypt gem to save memory.
    require_bcrypt? false

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { RodauthController }

    # Make built-in page titles accessible in your views via an instance variable.
    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Change some default param keys.
    login_param "username"
    login_column :username
    login_label "Username"
    require_login_confirmation? false

    # Redirect back to originally requested location after authentication.
    # login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    #
    # NOTE: We run custom cleanup in the `after_close_account` hook that destroys
    # the account row itself. Because Rodauth's built‑in flow runs
    # `after_close_account` *before* the hard delete, we can leave the default
    # behaviour enabled.
    delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # ==> Emails
    # Email sending is disabled by not enabling email-dependent features
    # and not configuring a mailer.

    # ==> Flash
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created successfully."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this username doesn't exist"
    # already_an_account_with_this_login_message "user with this username already exists"
    password_too_short_message { "must be at least #{password_minimum_length} characters" }
    passwords_do_not_match_message "passwords don't match"
    invalid_password_message "incorrect password"
    password_pwned_message "has been found in a data breach - please choose another"
    # login_does_not_meet_requirements_message { "invalid username#{", #{login_requirement_message}" if login_requirement_message}" }

    # Require strong passwords - min 12 characters
    password_minimum_length 12
    # Having a maximum password length set prevents long password DoS attacks.
    password_maximum_length 128

    # ==> Pwned Password Settings
    # Configure pwned password requests with timeout and error handling
    pwned_request_options open_timeout: 3, read_timeout: 5, headers: { "User-Agent" => "Libreverse App" }

    # Handle errors from the Pwned Passwords API with better logging and retry mechanism
    on_pwned_error do |error|
      log_msg = "API Error during pwned password check: #{error.class} - #{error.message}"

      # Log with appropriate severity based on error type
      if error.is_a?(Net::OpenTimeout) || error.is_a?(Net::ReadTimeout)
        Rails.logger.warn log_msg
      else
        Rails.logger.error log_msg
        Rails.logger.error error.backtrace.join("\n") if error.backtrace
      end

      # Record the failure for monitoring if Instrumentation is defined
      if defined?(Instrumentation)
        Instrumentation.record_error("pwned_password_api_error",
                                     error_class: error.class.to_s,
                                     error_message: error.message)
      end

      # Don't consider as pwned if API fails - but mark we had an API failure
      # so we can inform the user the check wasn't completed
      begin
        scope.instance_variable_set(:@pwned_check_failed, true)
      rescue StandardError
        nil
      end
      false
    end

    # ==> Implementing streamlined pwned password check
    # Perform pwned check in after_login hook which runs before response is sent
    after_login do
      # Remember the user only if EEA mode is disabled or the user opted in via consent screen
      if !EEAMode.enabled? || request.cookies["remember_opt_in"] == "1"
        remember_login
      else
        Rails.logger.debug "[Rodauth] Skipping remember_login – no opt‑in cookie while EEA mode active"
      end

      pwned_redirect_needed = false
      # Capture password and perform pwned check
      if param_or_nil(password_param)
        current_password = param(password_param)

        begin
          if password_pwned?(current_password)
            Rails.logger.warn "SECURITY: Pwned password detected for account #{account_id}"
            # Set the flag to force password change
            session[:password_pwned] = true
            flash_alert password_pwned_message # Use helper for consistency

            # Mark that we need to redirect to change password
            pwned_redirect_needed = true
            # Don't redirect immediately, handle it after the main logic
          else
            # Clear any existing pwned flag
            session.delete(:password_pwned)
          end
        rescue StandardError => e
          Rails.logger.error "Pwned check failed: #{e.message}"
          # Continue login flow if pwned check fails
        end

        # Save password metadata in session
        set_session_value(:password_length, current_password.length)
        set_session_value(:last_login_at, Time.now.to_i)
      end

      # --- Pwned Redirect Logic (Only) ---
      # Prioritize pwned password redirect
      if pwned_redirect_needed
        target_path = change_password_path # Use path helper if available
        Rails.logger.info "[Rodauth] Pwned password detected, redirecting to: #{target_path}"
        # Use Rodauth's base redirect. If this causes issues with Turbo, we may need to revisit.
        redirect target_path
        # Halt further processing in this hook since we're redirecting
        return
      end

      # For successful logins (not pwned), set flash and allow Rodauth default flow.
      # The controller will handle the final redirect based on request format.
      if login_notice_flash
        set_notice_flash login_notice_flash
        Rails.logger.info "[Rodauth] Successful login (after_login), set flash. Controller will handle redirect."
      end
    end

    # Validate passwords are not pwned during password changes and registration
    password_meets_requirements? do |password|
      # Run the basic requirements check
      basic_requirements = super(password)

      # Only perform pwned check if basic requirements pass
      if basic_requirements
        # Check if password is pwned
        begin
          if password_pwned?(password)
            Rails.logger.warn "SECURITY: Pwned password rejected during validation"
            @password_requirement_message = password_pwned_message
            return false
          end
        rescue StandardError => e
          Rails.logger.error "Error during pwned validation: #{e.message}"
          # Don't fail validation if API check fails
        end
      end

      basic_requirements
    end

    # Clear the pwned flag after successful password change and redirect to original path if available
    after_change_password do
      # Update password_changed_at timestamp
      db.from(accounts_table).where(id: account_id).update(password_changed_at: Time.zone.now)

      # Update password length in session
      set_session_value(:password_length, param(password_param).length)

      # Clear password_pwned flag
      session.delete(:password_pwned)

      # Show success message
      flash[:notice] = "Your password has been changed successfully."

      # Redirect to the saved return path if available, otherwise use default
      if session[:return_to_after_password_change]
        redirect_url = session.delete(:return_to_after_password_change)
        Rails.logger.info "Redirecting to saved path after password change: #{redirect_url}"
        redirect redirect_url
      end
    end

    # ==> Remember Feature
    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # ==> Hooks
    # Validate custom fields in the create account form.
    # before_create_account do
    #   throw_error_status(422, "name", "must be present") if param("name").empty?
    # end

    # Perform additional actions after the account is created.
    # after_create_account do
    #   Profile.create!(account_id: account_id, name: param("name"))
    # end

    # Do additional cleanup after the account is closed.
    after_close_account do
      # Remove user preferences
      UserPreference.where(account_id: account_id).delete_all

      # Destroy experiences and purge attached files
      Experience.where(account_id: account_id).find_each do |exp|
        exp.html_file.purge_later if exp.html_file.attached?
        exp.destroy!
      end
    end

    # ==> Redirects
    # Redirect to dashboard after login.
    def login_redirect
      # Use path helper if available, otherwise use string path
      defined?(dashboard_path) ? dashboard_path : "/dashboard"
    end

    # Redirect to login page after logout.
    # logout_redirect "/login"

    # Redirect to login page after closing account.
    # close_account_redirect "/login"

    # Redirect somewhere else after creating account.
    # create_account_redirect { login_path }

    # Redirect somewhere else after resetting password.
    # reset_password_redirect { login_path }

    # Redirect somewhere else after changing password.
    # change_password_redirect { user_profile_path }

    # Redirect somewhere else after changing login.
    # change_login_redirect { user_profile_path }

    # Return path for remember feature. Remembered user is redirected
    # to this path when clicking link in email.
    # remember_redirect { login_path }

    # ==> Deadlines
    # Change default deadlines for some features.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval 1.hour.to_i
    # verify_login_change_deadline_interval 1.hour.to_i
    # remember_deadline_interval 1.week.to_i

    # Override email validation for username
    auth_class_eval do
      def login_meets_requirements?(_login)
        true
      end
    end

    # Custom error message for username requirements
    login_does_not_meet_requirements_message "must be at least 3 characters"

    # Set proper after-creation behavior
    create_account_autologin? true
    create_account_set_password? true

    # Skip account verification step since we're using usernames
    skip_status_checks? true

    # Set timestamps before account creation to avoid constraint errors
    before_create_account do
      # Set timestamps to prevent database constraint violations
      now = Time.current
      account[:created_at] = now
      account[:updated_at] = now

      # Validate username for inappropriate content
      username = param(login_param)
      if username.present? && ModerationService.contains_inappropriate_content?(username)
        violations = ModerationService.get_violation_details(username)

        # Log the violation
        reason = if violations.empty?
          "content flagged by comprehensive moderation system"
        else
          violations.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
        end

        Rails.logger.warn "Moderation violation in account creation username: #{reason}"

        # Throw validation error - this will prevent account creation and show error to user
        throw_error_status(422, login_param, "contains inappropriate content and cannot be saved")
      end
    end

    # Auto-verify accounts immediately after creation
    after_create_account do
      # Directly mark the account as verified
      db.from(accounts_table).where(id: account_id).update(
        status: 2, # verified
        password_changed_at: Time.zone.now
      )

      # --- Assign first non-guest account as admin --- Start
      account_info = db.from(accounts_table).where(id: account_id).first
      is_guest = account_info && account_info[:guest] == true

      if is_guest
        Rails.logger.debug "[Rodauth][after_create_account] Account ID: #{account_id} is a guest. Skipping admin check."
      else
        # Check if any *other* admin exists (excluding guests)
        admin_exists = db.from(accounts_table).where(admin: true, guest: false).exclude(id: account_id).count.positive?

        if admin_exists
          Rails.logger.debug "[Rodauth][after_create_account] Admin already exists. Skipping admin assignment for account ID: #{account_id}"
        else
          Rails.logger.info "[Rodauth][after_create_account] Assigning admin role to first non-guest account ID: #{account_id}"
          db.from(accounts_table).where(id: account_id).update(admin: true)
        end
      end
      # --- Assign first non-guest account as admin --- End

      # Save password length in session
      set_session_value(:password_length, param(password_param).length)

      db.after_commit do
        set_notice_flash create_account_notice_flash
        redirect create_account_redirect
      end
    end

    before_login do
      Rails.logger.info "DEBUG: Entered before_login hook"
    end

    # Argon2 cost already configured globally

    # Allow programmatic close without password confirmation when invoked from dashboard controller
    close_account_requires_password? false
  end
  # rubocop:enable Metrics/BlockLength
  Rails.logger.info "RodauthMain configuration loaded"

  # ==> Redirects (Define methods outside configure block)
  # ... other potential redirect methods like logout_redirect etc. ...
end
