# XML-RPC security blocks
Rails.application.config.middleware.insert_before 0, Rack::Runtime do
  use Rack::Protection::XSSHeader
  use Rack::Protection::ContentSecurityPolicy, frame_options: "DENY"

  # Validate content types for XML-RPC API
  use Rack::Protection::Base do |env|
    if env["PATH_INFO"] == "/api/xmlrpc" && env["REQUEST_METHOD"] == "POST"
      content_type = env["CONTENT_TYPE"]
      # Only allow multipart/form-data for XML-RPC requests
      !content_type&.include?("multipart/form-data")
    else
      false
    end
  end
end
