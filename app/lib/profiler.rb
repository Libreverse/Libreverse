# frozen_string_literal: true

# Profiler provides richer profiling helpers in development, including StackProf and Flamegraph.
module Profiler
  def self.stackprof(mode: :wall, out: 'tmp/stackprof.dump')
    return yield unless Rails.env.development?

    require 'stackprof'
    StackProf.run(mode: mode, out: out, raw: true) { yield }
  end

  def self.flamegraph(out: 'tmp/flamegraph.html')
    return yield unless Rails.env.development?

    require 'flamegraph'
    Flamegraph.generate(out) { yield }
  end

  def self.mini_step(name)
    return yield unless defined?(Rack::MiniProfiler) && Rails.env.development?

    Rack::MiniProfiler.step(name) { yield }
  end
end
