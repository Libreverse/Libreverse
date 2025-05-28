# frozen_string_literal: true

require "voight_kampff"

class BotBlocker
  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip bot detection for certain paths that should always be accessible
    request = Rack::Request.new(env)
    
    # Allow robots.txt, security.txt, and admin routes to pass through
    return @app.call(env) if skip_bot_detection?(request.path)

    # Check if no bots mode is enabled
    return @app.call(env) unless no_bots_mode_enabled?

    # Check if the request is from a bot
    if bot_request?(env)
      Rails.logger.info "[BotBlocker] Blocking bot request from #{request.ip} - User-Agent: #{request.user_agent}"
      
      # Return 403 Forbidden for bots
      return [
        403,
        {
          "Content-Type" => "text/plain",
          "Content-Length" => "9"
        },
        ["Forbidden"]
      ]
    end

    @app.call(env)
  end

  private

  def skip_bot_detection?(path)
    # Allow these paths to always be accessible
    allowed_paths = [
      "/robots.txt",
      "/.well-known/security.txt",
      "/.well-known/privacy.txt"
    ]
    
    # Allow admin routes (admins need to be able to configure the setting)
    return true if path.start_with?("/admin")
    
    allowed_paths.any? { |allowed_path| path == allowed_path }
  end

  def no_bots_mode_enabled?
    # Check the instance setting for no_bots_mode
    # Use a cached approach to avoid hitting the database on every request
    @no_bots_mode_cache ||= {}
    cache_key = "no_bots_mode_#{Time.current.to_i / 60}" # Cache for 1 minute
    
    return @no_bots_mode_cache[cache_key] if @no_bots_mode_cache.key?(cache_key)
    
    begin
      # Clear old cache entries
      @no_bots_mode_cache.clear if @no_bots_mode_cache.size > 5
      
      setting_value = InstanceSetting.get("no_bots_mode")
      enabled = setting_value.to_s.downcase.in?(%w[true 1 yes on enabled])
      @no_bots_mode_cache[cache_key] = enabled
      enabled
    rescue StandardError => e
      Rails.logger.error "[BotBlocker] Error checking no_bots_mode setting: #{e.message}"
      false # Default to allowing requests if we can't check the setting
    end
  end

  def bot_request?(env)
    begin
      # Use voight-kampff to detect bots
      VoightKampff.bot?(env["HTTP_USER_AGENT"])
    rescue StandardError => e
      Rails.logger.error "[BotBlocker] Error in bot detection: #{e.message}"
      false # Default to not blocking if detection fails
    end
  end
end 