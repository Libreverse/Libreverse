# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Standalone profiler for development: runs StackProf over configured routes,
# prints top methods and per-module breakdown, and optionally emits a flamegraph.
#
# Usage examples:
#   bundle exec ruby scripts/profile_modules.rb
#   MODE=cpu RUNS=5 PATHS="/,/robots.txt" OUT=tmp/stackprof.dump bundle exec ruby scripts/profile_modules.rb
#   FLAME=tmp/flamegraph.html bundle exec ruby scripts/profile_modules.rb

require 'bundler/setup'
ENV['RAILS_ENV'] ||= 'development'

require_relative '../config/environment'
require 'rack/mock'
# require 'stackprof'  # Removed for TruffleRuby compatibility

MODE  = (ENV['MODE'] || 'wall').to_sym
RUNS  = (ENV['RUNS'] || '3').to_i
OUT   = ENV['OUT'] || 'tmp/stackprof.dump'
HOST  = ENV['HOST'] || 'localhost:3000'
PATHS = (ENV['PATHS'] || '/,/robots.txt').split(',').map(&:strip).reject(&:empty?)
FLAME = ENV['FLAME'] # set to a file path like tmp/flamegraph.html to generate

app = Rails.application
mock = Rack::MockRequest.new(app)

def hit(mock, path, host)
  mock.get(path, 'HTTP_HOST' => host, 'HTTPS' => 'on', 'HTTP_USER_AGENT' => 'Profiler')
rescue StandardError => e
  warn "Request error for #{path}: #{e.class} #{e.message}"
end

def exercise(mock, host, paths, runs)
  runs.times do
    paths.each { |p| hit(mock, p, host) }
  end
end

puts "Profiling with StackProf mode=#{MODE}, runs=#{RUNS}, paths=#{PATHS.join(' ')}"

  # StackProf.run(mode: MODE, out: OUT, raw: true) do  # Removed for TruffleRuby compatibility
  exercise(mock, HOST, PATHS, RUNS)
# end

# data = Marshal.load(File.binread(OUT))  # Removed for TruffleRuby compatibility

# Summaries
total_samples = 0
frames = {}

sorted = frames.values
               .select { |f| f[:samples].to_i.positive? }
               .sort_by { |f| -f[:samples].to_i }
               .first(25)

puts "\nTop 25 methods by samples (#{total_samples} total):"
i = 0
while i < sorted.length
  f = sorted[i]
  name = f[:name]
  samples = f[:samples]
  loc = f[:file] && f[:line] ? "#{f[:file]}:#{f[:line]}" : ""
  pct = total_samples.positive? ? (100.0 * samples / total_samples) : 0
  puts format("%2d. %-60s %8d samples  %5.1f%%  %s", i + 1, name, samples, pct, loc)
  i += 1
end

# Aggregate by module/class prefix: split on # or . and use the left side
by_module = Hash.new(0)
frames.each_value do |f|
  next unless (s = f[:samples].to_i).positive?

  name = f[:name].to_s
  mod = name.split(/[#.]/, 2).first
  by_module[mod] += s
end

mod_sorted = by_module.sort_by { |_, s| -s }.first(20)

puts "\nTop 20 modules/classes by samples:"
i2 = 0
while i2 < mod_sorted.length
  mod, s = mod_sorted[i2]
  pct = total_samples.positive? ? (100.0 * s / total_samples) : 0
  puts format("%2d. %-40s %8d samples  %5.1f%%", i2 + 1, mod, s, pct)
  i2 += 1
end

if FLAME && !FLAME.strip.empty?
  begin
    require 'flamegraph'
    puts "\nGenerating flamegraph at #{FLAME} ..."
    Flamegraph.generate(FLAME) do
      exercise(mock, HOST, PATHS, 1)
    end
    puts "Flamegraph written to #{FLAME}"
  rescue LoadError
    warn "flamegraph gem not available; skipping flamegraph generation"
  end
end

puts "\nDone. Profiling completed (StackProf removed for TruffleRuby compatibility)"
