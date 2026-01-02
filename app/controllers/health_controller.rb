# frozen_string_literal: true
# shareable_constant_value: literal

class HealthController < ApplicationController
  # Skip authentication and other filters for health checks
  skip_before_action :global_spam_protection_check
  skip_before_action :disable_browser_cache
  skip_before_action :initialize_guest_preferences
  skip_before_action :log_request_info
  skip_before_action :set_current_ip
  skip_before_action :set_locale
  
  # Override authentication check to allow health endpoints
  before_action :allow_health_access
  
  private
  
  def allow_health_access
    # Allow access to health endpoints without authentication
    return if action_name.in?(%w[show anycable])
    
    # For other actions, use normal authentication
    require_authentication if respond_to?(:require_authentication)
  end
  
  def show
    render json: { status: "ok", timestamp: Time.current.iso8601 }, status: :ok
  end

  def anycable
    # Check if AnyCable RPC server is accessible
    rpc_host = Rails.application.config.x.anycable_rpc_host
    health_status = {
      status: "ok",
      timestamp: Time.current.iso8601,
      rpc_host: rpc_host,
      adapter: Rails.application.config.action_cable.adapter
    }

    # Try to check Redis connectivity if using Redis
    if Rails.application.config.cable.adapter == :anycable
      begin
        redis_url = Rails.application.config.cable.url
        require "redis"
        redis = Redis.new(url: redis_url)
        redis.ping
        health_status[:redis] = "connected"
      rescue StandardError => e
        health_status[:status] = "error"
        health_status[:redis] = "disconnected"
        health_status[:error] = e.message
        render json: health_status, status: :service_unavailable
        return
      end
    end

    render json: health_status, status: :ok
  rescue StandardError => e
    render json: { 
      status: "error", 
      timestamp: Time.current.iso8601, 
      error: e.message 
    }, status: :service_unavailable
  end
end
