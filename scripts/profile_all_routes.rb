# Profiles (most) GET routes automatically and prints a breakdown by method and module/class.
# Writes a StackProf dump you can re-analyze, and optionally a flamegraph HTML.
#
# Usage (one command):
#   bundle exec ruby scripts/profile_all_routes.rb
#
# Optional env:
#   MODE=cpu RUNS=3 HOST=localhost:3000 OUT=tmp/stackprof_all.dump FLAME=tmp/flame_all.html bundle exec ruby scripts/profile_all_routes.rb

require 'bundler/setup'
ENV['RAILS_ENV'] ||= 'development'

require_relative '../config/environment'
require 'rack/mock'
require 'stackprof'
require 'active_support/notifications'
require 'fileutils'

MODE       = (ENV['MODE'] || 'wall').to_sym
RUNS       = (ENV['RUNS'] || '2').to_i
OUT        = ENV['OUT'] || 'tmp/stackprof_all.dump'
HOST       = ENV['HOST'] || 'localhost:3000'
flame_env  = ENV['FLAME']
FLAME_FILE = if flame_env && !flame_env.strip.empty?
               flame_env.match?(/\A(1|true|yes)\z/i) ? 'tmp/flame_all.html' : flame_env
end
SLOW_MS = (ENV['SLOW_MS'] || '50').to_f

app = Rails.application
mock = Rack::MockRequest.new(app)

SKIP_ROUTE_PATTERNS = [
  %r{^/rails/active_storage},
  %r{^/rails/mailers},
  %r{^/assets},
  %r{^/packs},
  %r{^/cable},
  %r{^/auth},            # OmniAuth
  %r{^/users/auth},      # Devise/OmniAuth style
  %r{^/oauth}
].freeze

EXTRA_SKIPS = (ENV['SKIP'] || '').split(',').map(&:strip).reject(&:empty?).map { |s| Regexp.new(s) }

def sample_path(path)
  s = path.dup
  s = s.gsub(/\(\.:(?:format)\)/, '')
  s = s.gsub(/\*([a-zA-Z_]+)/, 'all')
  s = s.gsub(/:([a-zA-Z_]+)/) do
    name = Regexp.last_match(1)
    case name
    when /id/     then '1'
    when /slug/   then 'test-slug'
    when /token/  then 'tok123'
    when /format/ then 'json'
    else 'sample'
    end
  end
  s.start_with?('/') ? s : "/#{s}"
end

def discover_get_paths
  paths = []
  Rails.application.routes.routes.each do |r|
    verb = r.verb.to_s
    next unless /(GET|HEAD)/.match?(verb)

    raw = r.path.spec.to_s
  next if SKIP_ROUTE_PATTERNS.any? { |re| raw =~ re }
  next if EXTRA_SKIPS.any? { |re| raw =~ re }

    path = sample_path(raw)
    paths << path
  end
  paths.uniq
end

def hit(mock, path, host)
  mock.get(path, 'HTTP_HOST' => host, 'HTTPS' => 'on', 'HTTP_USER_AGENT' => 'ProfileAll')
rescue StandardError => e
  warn "Request error for #{path}: #{e.class} #{e.message}"
end

def exercise(mock, host, paths, runs)
  runs.times do
    paths.each { |p| hit(mock, p, host) }
  end
end

paths = discover_get_paths
puts "Discovered #{paths.size} GET/HEAD paths"

# Aggregate controller/action timings and SQL time
actions = Hash.new { |h, k| h[k] = { count: 0, total_ms: 0.0, db_ms: 0.0, view_ms: 0.0, statuses: Hash.new(0), sql: { count: 0, total_ms: 0.0, selects: 0, tables: Hash.new(0) } } }
sql_total_ms = 0.0
slow_queries = [] # [time_ms, sql, action]

# Simple SQL parser helpers
def normalize_sql(sql)
  s = sql.to_s.dup
  s.gsub!(/'(?:''|[^'])*'/, '?') # single-quoted
  s.gsub!(/"(?:""|[^"])*"/, '?') # double-quoted
  s.gsub!(/\b\d+\b/, '?')
  s.gsub!(/\s+/, ' ')
  s.strip
end

def extract_table(sql)
  s = sql.to_s
  return Regexp.last_match(1) if s =~ /\bfrom\s+[`"]?([\w.]+)[`"]?/i
  return Regexp.last_match(1) if s =~ /\binsert\s+into\s+[`"]?([\w.]+)[`"]?/i
  return Regexp.last_match(1) if s =~ /\bupdate\s+[`"]?([\w.]+)[`"]?/i
  return Regexp.last_match(1) if s =~ /\bdelete\s+from\s+[`"]?([\w.]+)[`"]?/i

  nil
end

curr_key = -> { Thread.current[:_prof_curr_action] }

ActiveSupport::Notifications.subscribe('start_processing.action_controller') do |*, payload|
  Thread.current[:_prof_curr_action] = "#{payload[:controller]}##{payload[:action]}"
end

sub_action = ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_name, start, finish, _id, payload|
  key = "#{payload[:controller]}##{payload[:action]}"
  dur_ms = (finish - start) * 1000.0
  db_ms = payload[:db_runtime].to_f
  view_ms = payload[:view_runtime].to_f
  status = (payload[:status] || 0).to_i
  a = actions[key]
  a[:count] += 1
  a[:total_ms] += dur_ms
  a[:db_ms] += db_ms
  a[:view_ms] += view_ms
  a[:statuses][status] += 1
  Thread.current[:_prof_curr_action] = nil
end

sub_sql = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
  next if payload[:name] == 'SCHEMA'

  dur = (finish - start) * 1000.0
  sql_total_ms += dur

  if (key = curr_key.call)
    a = actions[key]
    a[:sql][:count] += 1
    a[:sql][:total_ms] += dur
    a[:sql][:selects] += 1 if /\bselect\b/i.match?(payload[:sql].to_s)
    if (t = extract_table(payload[:sql]))
      a[:sql][:tables][t] += 1
    end
    slow_queries << [ dur, normalize_sql(payload[:sql]), key ] if dur >= SLOW_MS
  end
end

puts "Profiling with StackProf mode=#{MODE}, runs=#{RUNS}"
StackProf.run(mode: MODE, out: OUT, raw: true) do
  exercise(mock, HOST, paths, RUNS)
end

ActiveSupport::Notifications.unsubscribe(sub_action)
ActiveSupport::Notifications.unsubscribe(sub_sql)

data = Marshal.load(File.binread(OUT))
total_samples = data[:samples] || 0
frames = data[:frames] || {}

sorted = frames.values
               .select { |f| f[:samples].to_i.positive? }
               .sort_by { |f| -f[:samples].to_i }
               .first(30)

puts "\nTop 30 methods by samples (#{total_samples} total):"
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

# Controller actions breakdown (averages)
if actions.any?
  rows = actions.map do |key, a|
    avg = a[:total_ms] / a[:count]
    avg_db = a[:db_ms] / a[:count]
    avg_view = a[:view_ms] / a[:count]
    [ key, a[:count], avg, avg_db, avg_view ]
  end
  rows.sort_by! { |_, _, avg, _, _| -avg }
  puts "\nTop controller actions by avg total ms (count, avg_total, avg_db, avg_view):"
  rows.first(20).each do |key, count, avg, avg_db, avg_view|
    puts format("- %-40s %5d  total:%8.2fms  db:%8.2fms  view:%8.2fms", key, count, avg, avg_db, avg_view)
  end
  puts format("\nTotal ActiveRecord SQL time: %.2fms", sql_total_ms)
end

# SQL/N+1 indicators per action
sql_rows = actions.map do |key, a|
  next if a[:count] <= 0

  sql = a[:sql]
  avg_sql_ms = sql[:total_ms] / a[:count]
  avg_sql_count = sql[:count].to_f / a[:count]
  [ key, a[:count], avg_sql_ms, avg_sql_count, sql[:tables].sort_by { |_, c| -c }.first(3) ]
end.compact

if sql_rows.any?
  sql_rows.sort_by! { |_, _, avg_ms, avg_count, _| [ -avg_ms, -avg_count ] }
  puts "\nTop actions by avg SQL time and query count:"
  sql_rows.first(20).each do |key, count, avg_ms, avg_count, top_tables|
    tables = top_tables.map { |t, c| "#{t}(#{c})" }.join(', ')
    puts format("- %-40s %5d  sql:%8.2fms  queries:%5.1f  tables: %s", key, count, avg_ms, avg_count, tables)
  end
end

if slow_queries.any?
  puts "\nSlow queries (>= #{SLOW_MS.to_i}ms), top 10:"
  slow_queries.sort_by! { |dur, _, _| -dur }
  slow_queries.first(10).each do |dur, sql, key|
    puts format("- %8.2fms  %-50s  (%s)", dur, sql[0, 50], key)
  end
end

# Focus on your app code under app/ and lib/
app_root = Rails.root.to_s
app_sorted = frames.values
                   .select { |f| f[:samples].to_i.positive? && f[:file].to_s.start_with?("#{app_root}/app", "#{app_root}/lib") }
                   .sort_by { |f| -f[:samples].to_i }
                   .first(30)

puts "\nTop 30 methods by samples (app/ & lib/ only):"
i2 = 0
while i2 < app_sorted.length
  f = app_sorted[i2]
  name = f[:name]
  samples = f[:samples]
  loc = f[:file] && f[:line] ? "#{f[:file]}:#{f[:line]}" : ""
  pct = total_samples.positive? ? (100.0 * samples / total_samples) : 0
  puts format("%2d. %-60s %8d samples  %5.1f%%  %s", i2 + 1, name, samples, pct, loc)
  i2 += 1
end

by_module = Hash.new(0)
frames.each_value do |f|
  s = f[:samples].to_i
  next if s <= 0

  mod = f[:name].to_s.split(/[#.]/, 2).first
  by_module[mod] += s
end

puts "\nTop 20 modules/classes by samples:"
mod_list = by_module.sort_by { |_, s| -s }.first(20)
i3 = 0
while i3 < mod_list.length
  mod, s = mod_list[i3]
  pct = total_samples.positive? ? (100.0 * s / total_samples) : 0
  puts format("%2d. %-40s %8d samples  %5.1f%%", i3 + 1, mod, s, pct)
  i3 += 1
end

if FLAME_FILE && !FLAME_FILE.strip.empty?
  begin
    require 'flamegraph'
  puts "\nGenerating flamegraph at #{FLAME_FILE} ..."
    # One pass for a clean graph
    exercise(mock, HOST, paths, 1)
  FileUtils.mkdir_p(File.dirname(FLAME_FILE))
  Flamegraph.generate(FLAME_FILE) do
      exercise(mock, HOST, paths, 1)
  end
  puts "Flamegraph written to #{FLAME_FILE}"
  rescue LoadError
    warn "flamegraph gem not available; skipping flamegraph generation"
  end
end

puts "\nDone. StackProf dump at #{OUT}"
