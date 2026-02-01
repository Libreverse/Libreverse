# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Optional debug aid: profile eager loading and log requires.
# Enable with:
#   TRACE_EAGER_LOAD=1 bin/dev-server
# Output:
#   tmp/eager_load_trace.log
return unless ENV["TRACE_EAGER_LOAD"] == "1"

begin
  require "zeitwerk"

  trace_path = File.expand_path("../../tmp/eager_load_trace.log", __dir__)
  File.write(trace_path, "") unless File.exist?(trace_path)

  module EagerLoadTrace
    module_function

    def trace_path
      File.expand_path("../../tmp/eager_load_trace.log", __dir__)
    end

    def timestamp
      Time.now.utc.strftime("%Y-%m-%d %H:%M:%S.%6N")
    end

    def log(message)
      File.open(trace_path, "a") do |f|
        f.puts(message)
        f.flush
      end
    rescue StandardError
      nil
    end

    def active?
      Thread.current[:eager_load_trace_active] == true
    end

    def activate!
      Thread.current[:eager_load_trace_active] = true
    end

    def deactivate!
      Thread.current[:eager_load_trace_active] = false
    end
  end

  module EagerLoadTrace
    module LoaderPatch
      def eager_load(*args, **kwargs, &block)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        roots = respond_to?(:root_dirs) ? root_dirs.keys.join(",") : "unknown"
        EagerLoadTrace.log("#{EagerLoadTrace.timestamp} pid=#{Process.pid} eager_load start roots=#{roots}")
        EagerLoadTrace.activate!
        result = super
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000.0).round(3)
        EagerLoadTrace.log("#{EagerLoadTrace.timestamp} pid=#{Process.pid} eager_load finish duration_ms=#{duration_ms}")
        result
      ensure
        EagerLoadTrace.deactivate!
      end
    end
  end

  module EagerLoadTrace
    module RequirePatch
      def require(path)
        return super unless EagerLoadTrace.active?

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        EagerLoadTrace.log("#{EagerLoadTrace.timestamp} pid=#{Process.pid} require_start #{path}")
        result = super
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000.0).round(3)
        status = result ? "loaded" : "skipped"
        EagerLoadTrace.log("#{EagerLoadTrace.timestamp} pid=#{Process.pid} require_finish #{duration_ms}ms #{status} #{path}")
        result
      end
    end
  end

  Kernel.prepend(EagerLoadTrace::RequirePatch) unless Kernel.ancestors.include?(EagerLoadTrace::RequirePatch)
  if defined?(Zeitwerk::Loader)
    Zeitwerk::Loader.prepend(EagerLoadTrace::LoaderPatch) unless Zeitwerk::Loader.ancestors.include?(EagerLoadTrace::LoaderPatch)
  end
rescue StandardError
  # If anything goes wrong while enabling tracing, continue boot normally.
  nil
end
