# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Optional debug aid: log each initializer as it runs.
# Enable with:
#   TRACE_RAILS_INITIALIZERS=1 bin/rails runner 'puts :ok'
# Output:
#   tmp/initializer_trace.log
#
# Rationale: when the VM exits abruptly (native crash / hard exit), Ruby may not
# print a backtrace. The trace file helps pinpoint the last initializer reached.
#
return unless ENV["TRACE_RAILS_INITIALIZERS"] == "1"

begin
  require "rails/initializable"

  trace_path = File.expand_path("../../tmp/initializer_trace.log", __dir__)
  File.write(trace_path, "") unless File.exist?(trace_path)

  module LibreverseInitializerTrace
    def run(*args)
      begin
        trace_path = File.expand_path("../../tmp/initializer_trace.log", __dir__)
        File.open(trace_path, "a") do |f|
          f.puts("#{Time.now.utc} #{name}")
          f.flush
        end
      rescue StandardError
        nil
      end
      super
    end
  end

  Rails::Initializable::Initializer.prepend(LibreverseInitializerTrace)
rescue StandardError
  # If anything goes wrong while enabling tracing, continue boot normally.
  nil
end
