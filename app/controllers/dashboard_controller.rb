# frozen_string_literal: true

require "digest"

class DashboardController < ApplicationController
  before_action :set_cache_headers_for_dashboard

  def index
    @account = current_account
    @account_created_at = @account.created_at.strftime("%B %d, %Y")
    @last_login_at = session[:last_login_at] ? Time.zone.at(session[:last_login_at]).strftime("%B %d, %Y at %H:%M") : "Unknown"
    @time_since_joining = time_since_joining(@account.created_at)

    # Calculate password strength level
    @password_strength = { level: calculate_strength_level }

    # Generate ETag for dashboard based on account info and last login
    last_login_timestamp = session[:last_login_at] || 0
    cache_key = "dashboard/#{@account.id}/#{@account.updated_at.to_i}/#{last_login_timestamp}"
    etag = Digest::MD5.hexdigest(cache_key)

    # Handle conditional requests - dashboard content is mostly static per user
    # Handle conditional requests (skip in development to avoid masking errors)
    return if Rails.env.development?

      nil unless stale?(etag: etag, public: false)

    # Content has changed or no ETag in request, proceed with rendering
  end

  private

  def set_cache_headers_for_dashboard
    # Cache dashboard for 10 minutes since it's mostly static user info
    # Skip cache headers in development to avoid masking application errors
    expires_in 10.minutes, public: false unless Rails.env.development?
  end

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
