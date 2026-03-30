# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class FederatedLoginController < ApplicationController
  include FederatedAuthHelper

  def create
    result = ::FederatedLogin::Create.call(
      params: params,
      session: session,
      helper: self
    )

    unless result.success?
      flash[:error] = result[:error]
      return redirect_to login_path
    end

    # Redirect to OmniAuth for authentication
    redirect_to "/auth/federated"
  end

  # Handle OmniAuth callback
  def callback
    result = ::FederatedLogin::Callback.call(
      request: request,
      session: session
    )

    if result.success?
      flash[:notice] = result[:notice]
      redirect_to after_login_path
    else
      flash[:error] = result[:error]
      redirect_to login_path
    end
  rescue StandardError => e
    Rails.logger.error "Error in federated authentication callback: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:error] = "An error occurred during authentication. Please try again."
    redirect_to login_path
  end

  def failure
    error_type = params[:error] || params[:message] || "unknown"
    Rails.logger.warn "Federated authentication failed: #{error_type}"

    # Clean up session
    session.delete(:client_id)
    session.delete(:client_secret)
    session.delete(:oidc_domain)
    session.delete(:federated_username)
    session.delete(:federated_identifier)

    error_message = case error_type
    when "federation_failed"
                      "Federation authentication failed. Please check your identifier and try again."
    when "access_denied"
                      "Access was denied by the authentication provider."
    when "invalid_request"
                      "Invalid authentication request."
    else
                      "Authentication failed. Please try again."
    end

    flash[:error] = error_message
    redirect_to login_path
  end

  def new
    # Show federated login form
    # Pre-fill identifier if coming from a redirect
    @identifier = params[:identifier] || session[:pending_federated_login]
    session.delete(:pending_federated_login) # Clear after use
  end

  private

  def login_path
    # Use Rodauth's login path
    "/login"
  end

  def after_login_path
    # Redirect to dashboard after successful login
    "/dashboard"
  end

  def login_account(account)
    # Set the session to log in the user
    session[:account_id] = account.id
    # This mimics what Rodauth does for login
    session[:authenticated] = true
  end
end
