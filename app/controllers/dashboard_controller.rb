# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @account = current_account
    @account_created_at = @account.created_at.strftime("%B %d, %Y")
    @last_login_at = session[:last_login_at] ? Time.zone.at(session[:last_login_at]).strftime("%B %d, %Y at %H:%M") : "Unknown"
    @time_since_joining = time_since_joining(@account.created_at)

    # Calculate password strength level
    @password_strength = { level: calculate_strength_level }

    # Enhanced caching with Last-Modified and better ETags
    last_login_timestamp = session[:last_login_at] || 0
    content_fingerprint = "#{last_login_timestamp}/#{calculate_strength_level}"

    # Use enhanced caching with both ETag and Last-Modified
    nil if fresh_when_enhanced(
      etag_content: content_fingerprint,
      last_modified: [ @account.updated_at, Time.zone.at(last_login_timestamp) ].max,
      public: false,
      weak_etag: true
    )

    # Content has changed or no cache headers match, proceed with rendering
  end

  private

  def time_since_joining(created_at)
    days = (Time.zone.now - created_at).to_i / 1.day
    years = days / 365
    months = (days % 365) / 30
    days %= 30

    if years.positive?
      "#{years} #{years == 1 ? 'year' : 'years'}, #{months} #{months == 1 ? 'month' : 'months'}"
    elsif months.positive?
      "#{months} #{months == 1 ? 'month' : 'months'}, #{days} #{days == 1 ? 'day' : 'days'}"
    else
      "#{days} #{days == 1 ? 'day' : 'days'}"
    end
  end

  def calculate_strength_level
    password_length = session[:password_length] || 0

    # Basic strength calculation based on length
    strength = if password_length < 12
                 "weak"
    elsif password_length < 16
                 "medium"
    elsif password_length < 20
                 "strong"
    else
                 "very strong"
    end

    # Additional strength indicators from rodauth
    if session[:password_pwned]
      # If password is found in breach database, it's always weak
      strength = "weak"
    end

    strength
  end
end
