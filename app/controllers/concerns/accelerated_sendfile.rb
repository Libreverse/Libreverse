# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

module AcceleratedSendfile
  extend ActiveSupport::Concern

  private

# Contract
# - path: Absolute filesystem path within an accelerated root (e.g. storage/ or private/)
# - filename: Suggested filename for the client (defaults to File.basename(path))
# - type: MIME type (attempts to infer if omitted)
# - disposition: 'attachment' (default) or 'inline'
# Error modes: raises ArgumentError for unsafe/non-absolute paths
def accelerated_send_file(path, filename: nil, type: nil, disposition: "attachment", status: 200)
    p = Pathname.new(path)
    raise ArgumentError, "accelerated_send_file requires an absolute path" unless p.absolute?

    # Basic guard against path traversal into unexpected volumes
    # Allow at least these two whitelisted roots which are mapped in NGINX.
    allowed_roots = [ Rails.root.join("storage").to_s, Rails.root.join("private").to_s ]
    raise ArgumentError, "path is not under an allowed accelerated root" unless allowed_roots.any? { |root| p.to_s.start_with?("#{root}/") || p.to_s == root }

    # Delegate to Rails, which cooperates with Rack::Sendfile + X-Accel-Redirect in production
    send_file p.to_s,
              filename: filename || p.basename.to_s,
              type: type,
              disposition: disposition,
              status: status
end
end
