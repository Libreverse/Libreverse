# frozen_string_literal: true

# Middleware Configuration
# This file sets up the middleware stack for the application

# NOTE: Specific middleware configurations (HtmlCompressor, MaximumBodySize, Rack::Attack, IpAnonymizer)
# have been moved to their dedicated initializer files.

# ===== Compression Middleware =====
# Compression is now simplified to avoid Safari 'cannot decode raw data' errors caused by
# double-compression. We only use Rack::Brotli in production – it will fall back to gzip
# automatically when the client doesn't advertise `br`.

# ===== Emoji Processing (Middleware for HTTP Requests) =====
# We insert the emoji middleware here so that it precedes
# the html minifier but still avoids unnecessary work
# (Emoji processing logic is in config/initializers/emoji_replacer.rb)
