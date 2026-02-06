#!/usr/bin/env ruby

# Real-time Passenger spawn monitor
require 'fileutils'

LOG_FILE = "/Users/george/Libreverse/tmp/boot_trace.log"
PASSENGER_LOG = "/Users/george/Libreverse/log/passenger.3002.log"

# Monitor both files in real-time
threads = []

# Monitor boot trace
threads << Thread.new do
  if File.exist?(LOG_FILE)
    IO.popen("tail -f #{LOG_FILE}") do |io|
      while line = io.gets
        puts "🚀 BOOT: #{line.strip}"
      end
    end
  end
end

# Monitor passenger log
threads << Thread.new do
  if File.exist?(PASSENGER_LOG)
    IO.popen("tail -f #{PASSENGER_LOG}") do |io|
      while line = io.gets
        puts "PASSENGER: #{line.strip}" if line.match?(/ERROR|WARN|timeout|spawn|starting|online/)
      end
    end
  end
end

# Monitor process table
threads << Thread.new do
  loop do
    sleep 5
    passenger_procs = `ps aux | grep passenger | grep -v grep`.lines
    ruby_procs = `ps aux | grep truffleruby | grep -v grep`.lines
    
    puts "📊 #{Time.now.strftime('%H:%M:%S')} - Passenger processes: #{passenger_procs.length}, TruffleRuby processes: #{ruby_procs.length}"
    
    if passenger_procs.length > 0
      puts "CPU: #{passenger_procs.map { |p| p.split[2].to_f }.sum.round(1)}%"
    end
  end
end

threads.each(&:join)
