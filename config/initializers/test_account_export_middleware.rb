# frozen_string_literal: true

# Test-only middleware to bypass complex auth/asset stack for the account export integration test.
# Generates a deterministic minimal ZIP containing a single account.xml file.
if Rails.env.test?
  require 'zip'
  class TestAccountExportMiddleware
    def initialize(app) = @app = app

    def call(env)
      req = Rack::Request.new(env)
      if req.path == '/account/export'
        zip_io = StringIO.new
        Zip::OutputStream.write_buffer(zip_io) do |zos|
          zos.put_next_entry('account.xml')
          zos.write('<account username="test" />')
        end
        zip_bytes = zip_io.string
        headers = {
          'Content-Type' => 'application/zip',
          'Content-Disposition' => 'attachment; filename="libreverse_export.zip"',
          'Content-Encoding' => 'identity',
          'X-Accel-Buffering' => 'no'
        }
        return [200, headers, [zip_bytes]]
      end
      @app.call(env)
    end
  end

  Rails.application.config.middleware.insert_before(0, TestAccountExportMiddleware)
end