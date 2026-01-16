# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Development/test middleware that guarantees /blog pages have CSS/JS tags
# in <head> by injecting proxied Vite assets if they are missing.
class DevBlogHeadAssets
  CSS_TAG = %(<link rel="stylesheet" href="/vite-dev/stylesheets/application.scss" data-turbo-track="reload">)
  JS_TAG  = %(<script type="module" src="/vite-dev/javascript/application.js" data-turbo-track="reload"></script>)

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    begin
      return [ status, headers, response ] unless Rails.env.development? || Rails.env.test?

      path = env["PATH_INFO"]
      ctype = headers["Content-Type"]
      return [ status, headers, response ] unless path&.start_with?("/blog")
      return [ status, headers, response ] unless ctype&.include?("text/html")

      body = to_string(response)
      return [ status, headers, [ body ] ] unless body&.include?("<head")

      # Only inject if our tags are missing
      unless body.include?("/vite-dev/javascript/application.js") || body.include?("/vite-dev/stylesheets/application.scss")
        injection = "\n#{CSS_TAG}\n#{JS_TAG}\n"
        body.sub!(/<head[^>]*>/i) { |m| m + injection }
        headers["Content-Length"] = body.bytesize.to_s if headers["Content-Length"]
        response = [ body ]
      end

      [ status, headers, response ]
    rescue StandardError => e
      Rails.logger.warn("[DevBlogHeadAssets] injection skipped: #{e.class}: #{e.message}")
      [ status, headers, response ]
    end
  end

  private

  def to_string(resp)
    if resp.respond_to?(:body)
      str = resp.body.to_s
      resp.close if resp.respond_to?(:close)
      str
    else
      buf = +""
      resp.each { |chunk| buf << chunk.to_s }
      buf
    end
  end
end
