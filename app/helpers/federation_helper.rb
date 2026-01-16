# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Helper module for federation-related functionality
module FederationHelper
  # Check if a domain is a Libreverse instance by calling its discovery endpoint
  # Uses split timeouts for more precise control over network operations
  def self.libreverse_instance?(domain)
    return false unless domain

    url = if URI::DEFAULT_PARSER.make_regexp(%w[http https]).match?(domain)
      domain
    else
      "https://#{domain}/.well-known/libreverse"
    end

    response = HTTParty.get(url, open_timeout: 3, read_timeout: 3)

    if response.code == 200
      data = JSON.parse(response.body)
      data["software"] == "libreverse"
    else
      false
    end
  rescue StandardError
    false
  end
end
