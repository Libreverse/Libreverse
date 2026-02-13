# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Trace Bundler.require to identify which gem hangs during boot
module BundlerRequireTrace
  class << self
    def log(message)
      return unless ENV["TRACE_BUNDLER_REQUIRE"] == "1"

      log_path = Rails.root.join("tmp/bundler_require_trace.log")
      File.open(log_path, "a") do |f|
        f.puts("#{Time.now.utc} pid=#{Process.pid} #{message}")
        f.flush
      end
    rescue StandardError
      nil
    end

    def trace_require(gem_name)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      log("require_start #{gem_name}")

      result = yield

      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000.0).round(3)
      log("require_finish #{duration_ms}ms #{gem_name}")

      result
    end
  end
end

# Patch Bundler to trace each gem require
module Bundler
  class << self
    alias original_require require

    def require(*groups)
      BundlerRequireTrace.log("Bundler.require start groups=#{groups.inspect}")

      # Get the list of gems that will be required
      specs = Bundler.definition.specs_for(groups)

      specs.each do |spec|
        BundlerRequireTrace.trace_require(spec.name) do
            original_require(spec.name)
        rescue LoadError => e
            # Some gems might not be require-able by name directly
            BundlerRequireTrace.log("require_failed #{spec.name} #{e.message}")
            nil
        end
      end

      BundlerRequireTrace.log("Bundler.require finish")
    end
  end
end
