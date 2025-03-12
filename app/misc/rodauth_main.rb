require "sequel/core"

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    enable :create_account,
           :login, :logout, :remember,
           :change_password, :change_login,
           :close_account, :argon2,
           :pwned_password

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)
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
    # hmac_secret "9fc60b90b3c586aedf891213d74197d702d2e74f4a614de9dab8fe6dd930826815316088e05a73bb8d30df65df6fbacb0d0d8ad31d01fa82c7abdd371ffdf4fe"

    # Use a rotatable password pepper when hashing passwords with Argon2.
    # argon2_secret { hmac_secret }

    # Since we're using argon2, prevent loading the bcrypt gem to save memory.
    require_bcrypt? false

    # Use path prefix for all routes.
    # prefix "/auth"

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
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # ==> Emails
    # Disable email sending completely
    send_email do |_email|
      # No-op implementation - don't send any emails
      nil
    end

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
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid username#{", #{login_requirement_message}" if login_requirement_message}" }

    # Require strong passwords - min 12 characters
    password_minimum_length 12
    # Having a maximum password length set prevents long password DoS attacks.
    password_maximum_length 128

    # ==> Pwned Password Settings
    password_pwned_message "has appeared in a data breach. For your security, please use a different password."
    
    # Configure pwned password requests with timeout and error handling
    pwned_request_options open_timeout: 3, read_timeout: 5, headers: { "User-Agent" => "Libreverse App" }
    
    # Handle errors from the Pwned Passwords API
    on_pwned_error do |error|
      Rails.logger.error "API Error during pwned password check: #{error.class} - #{error.message}"
      false # Don't consider as pwned if API fails
    end
    
    # ==> DEBUGGING: Added debug logging to troubleshoot pwned password check issues
    auth_class_eval do
      # Override password_pwned? to add debug logging
      def password_pwned?(password)
        Rails.logger.info "DEBUG: Entering password_pwned? with password length: #{password ? password.length : 'nil'}"
        result = super
        Rails.logger.info "DEBUG: Exiting password_pwned? with result: #{result}"
        result
      end
    end

    # ==> Implementing streamlined pwned password check    
    # Perform pwned check in after_login hook which runs before response is sent
    after_login do
      Rails.logger.info "DEBUG: Entering after_login hook"
      # Remember the user
      remember_login
      
      # Capture password and perform pwned check
      if param_or_nil(password_param)
        current_password = param(password_param)
        Rails.logger.info "DEBUG: Captured password for pwned check: #{current_password.length} chars"
        
        begin
          if password_pwned?(current_password)
            Rails.logger.warn "SECURITY: Pwned password detected for account #{account_id}"
            flash[:alert] = "Your password has been found in a data breach. Please change your password immediately for your security."
            redirect "/change-password"
          else
            Rails.logger.info "DEBUG: Password cleared pwned check"
          end
        rescue => e
          Rails.logger.error "Pwned check failed: #{e.message}"
          # Continue login flow if pwned check fails
        end
        
        # Save password metadata in session
        set_session_value(:password_length, current_password.length)
        set_session_value(:last_login_at, Time.now.to_i)
      else
        Rails.logger.error "DEBUG: No password parameter available in after_login"
      end
    end

    # Validate passwords are not pwned during password changes and registration
    password_meets_requirements? do |password|
      Rails.logger.info "DEBUG: Validating password requirements including pwned check"
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
        rescue => e
          Rails.logger.error "Error during pwned validation: #{e.message}"
          # Don't fail validation if API check fails
        end
      end
      
      basic_requirements
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
    # after_close_account do
    #   Profile.find_by!(account_id: account_id).destroy
    # end

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to login page after successful account creation
    create_account_redirect "/"

    # ==> Deadlines
    # Change default deadlines for some actions.
    # remember_deadline_interval Hash[days: 30]

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

    # Auto-verify accounts immediately after creation
    after_create_account do
      # Directly mark the account as verified
      db.from(accounts_table).where(id: account_id).update(
        status: 2, # verified
        password_changed_at: Time.now
      )
      
      # Save password length in session
      set_session_value(:password_length, param(password_param).length)
      
      db.after_commit do
        set_notice_flash create_account_notice_flash
        redirect create_account_redirect
      end
    end

    # Update password_changed_at timestamp when password is changed
    after_change_password do
      # Update password_changed_at timestamp
      db.from(accounts_table).where(id: account_id).update(password_changed_at: Time.now)
      
      # Update password length in session
      set_session_value(:password_length, param(password_param).length)
      
      # Show success message
      flash[:notice] = "Your password has been changed successfully."
    end

    before_login do
      Rails.logger.info "DEBUG: Entered before_login hook"
    end
  end
  Rails.logger.info "RodauthMain configuration loaded"
end
