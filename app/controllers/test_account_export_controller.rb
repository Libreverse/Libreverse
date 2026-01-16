# typed: false
#!/usr/bin/env ruby
# frozen_string_literal: true
# shareable_constant_value: literal

# Test-only minimal implementation of account export to isolate ZIP streaming
# from authentication, Rodauth constraints, and Vite asset compilation. Loaded
# only in test environment; production uses AccountActionsController.
class TestAccountExportController < ApplicationController
  include ZipKit::RailsStreaming
  layout false

  def show
    zip_kit_stream(filename: "libreverse_export.zip", type: "application/zip") do |zip|
      zip.write_deflated_file("account.xml") { |s| s << '<account username="test" />' }
    end
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["Content-Encoding"] = "identity"
  end
end
