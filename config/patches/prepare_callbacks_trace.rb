# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Optional debug aid: profile ActiveSupport::Reloader prepare callbacks.
# Enable with:
#   TRACE_PREPARE_CALLBACKS=1 bin/dev-server
# Output:
#   tmp/prepare_callbacks_trace.log
return unless ENV["TRACE_PREPARE_CALLBACKS"] == "1" && RUBY_ENGINE == "truffleruby"

begin
  require "active_support/callbacks"
  require "active_support/reloader"

  module PrepareCallbacksTrace
    module_function

    def trace_path
      File.expand_path("../../tmp/prepare_callbacks_trace.log", __dir__)
    end

    def timestamp
      Time.now.utc.strftime("%Y-%m-%d %H:%M:%S.%6N")
    end

    def label_for(filter)
      case filter
      when Symbol
        "symbol:#{filter}"
      when Proc
        location = filter.source_location
        location ? "proc:#{location.join(':')}" : "proc"
      else
        filter.class.name.to_s
      end
    end

    def log(message)
      File.open(trace_path, "a") do |f|
        f.puts(message)
        f.flush
      end
    rescue StandardError
      nil
    end

    def measure(name:, filter:, target:)
      return yield unless name == :prepare
      return yield unless target.is_a?(ActiveSupport::Reloader)

      label = label_for(filter)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      log("#{timestamp} pid=#{Process.pid} prepare_callback_start #{label}")

      result = yield
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000.0).round(3)
      log("#{timestamp} pid=#{Process.pid} prepare_callback_finish #{duration_ms}ms #{label}")
      result
    end
  end

  File.write(PrepareCallbacksTrace.trace_path, "") unless File.exist?(PrepareCallbacksTrace.trace_path)

  module PrepareCallbacksTrace
    module BeforePatch
      def call(env)
        target = env.target
        value = env.value
        halted = env.halted

        if !halted && user_conditions.all? { |c| c.call(target, value) }
          result_lambda = lambda do
            PrepareCallbacksTrace.measure(name: name, filter: filter, target: target) do
              user_callback.call(target, value)
            end
          end
          env.halted = halted_lambda.call(target, result_lambda)
          if env.halted
            target.send :halted_callback_hook, filter, name
          end
        end

        env
      end
    end
  end

  unless ActiveSupport::Callbacks::Filters::Before.ancestors.include?(PrepareCallbacksTrace::BeforePatch)
    ActiveSupport::Callbacks::Filters::Before.prepend(PrepareCallbacksTrace::BeforePatch)
  end
rescue StandardError
  # If anything goes wrong while enabling tracing, continue boot normally.
  nil
end
