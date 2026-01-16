# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Profiler provides richer profiling helpers in development, including Flamegraph.
module Profiler
  # def self.stackprof(mode: :wall, out: "tmp/stackprof.dump", &block)  # Removed for TruffleRuby compatibility
  #   return yield unless Rails.env.development?

  #   require "stackprof"
  #   StackProf.run(mode: mode, out: out, raw: true, &block)
  # end

  def self.flamegraph(out: "tmp/flamegraph.html", &block)
    return yield unless Rails.env.development?

    require "flamegraph"
    Flamegraph.generate(out, &block)
  end

  def self.mini_step(name, &block)
    return yield unless defined?(Rack::MiniProfiler) && Rails.env.development?

    Rack::MiniProfiler.step(name, &block)
  end
end
