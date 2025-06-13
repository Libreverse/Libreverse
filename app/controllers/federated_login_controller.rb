# frozen_string_literal: true

# Controller for handling federated login with other Libreverse instances
class FederatedLoginController < ApplicationController
  def create
    identifier = params[:identifier]
    user, domain = parse_identifier(identifier)

    unless domain
      flash[:error] = "Invalid identifier format. Use format: user@instance.com"
      return redirect_to "/login"
    end

    # Verify it's a Libreverse instance
    unless libreverse_instance?(domain)
      flash[:error] = "The specified domain is not a recognized Libreverse instance"
      return redirect_to "/login"
    end

    config = fetch_oidc_config(domain)
    unless config
      flash[:error] = "Unable to fetch OIDC configuration from #{domain}"
      return redirect_to "/login"
    end

    # Register as a dynamic OIDC client
    client_data = register_oidc_client(config, domain)
    unless client_data
      flash[:error] = "Failed to register with #{domain}"
      return redirect_to "/login"
    end

    # Store client data in session
    session[:federated_login] = {
      domain: domain,
      user: user,
      client_id: client_data["client_id"],
      client_secret: client_data["client_secret"],
      config: config
    }

    # Redirect to dynamic OIDC provider
    redirect_to "/auth/dynamic"
  end

  private

  def parse_identifier(identifier)
    return nil unless identifier.include?("@")

    parts = identifier.split("@")
    return nil unless parts.length == 2

    user, domain = parts
    return nil if user.blank? || domain.blank?

    [ user, domain ]
  end

  def libreverse_instance?(domain)
    uri = URI("https://#{domain}/.well-known/libreverse")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    if response.code == "200"
      data = JSON.parse(response.body)
      data["software"] == "libreverse"
    else
      false
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to verify Libreverse instance #{domain}: #{e.message}"
    false
  end

  def fetch_oidc_config(domain)
    uri = URI("https://#{domain}/.well-known/openid-configuration")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    JSON.parse(response.body) if response.code == "200"
  rescue StandardError => e
    Rails.logger.warn "Failed to fetch OIDC config from #{domain}: #{e.message}"
    nil
  end

  def register_oidc_client(config, _domain)
    return nil unless config["registration_endpoint"]

    uri = URI(config["registration_endpoint"])

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      client_name: "Libreverse Instance (#{Rails.application.config.x.instance_domain})",
      redirect_uris: [ "#{request.base_url}/auth/dynamic/callback" ],
      grant_types: [ "authorization_code" ],
      response_types: [ "code" ],
      scope: "openid profile email"
    }.to_json

    response = http.request(request)

    if response.code.to_i >= 200 && response.code.to_i < 300
      JSON.parse(response.body)
    else
      Rails.logger.error "OIDC client registration failed: #{response.code} #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error registering OIDC client: #{e.message}"
    nil
  end
end
