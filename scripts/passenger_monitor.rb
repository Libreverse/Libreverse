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
        puts "#{line.strip}"
      end
    end
  end
end

# Monitor passenger log
threads << Thread.new do
  if File.exist?(PASSENGER_LOG)
    IO.popen("tail -f #{PASSENGER_LOG}") do |io|
      while line = io.gets
        puts "#{line.strip}"
      end
    end
  end
end

# Monitor process table
threads << Thread.new do
  loop do
    sleep 5
    passenger_procs = `ps aux | grep passenger | grep -v grep`.lines
    
    if passenger_procs.length > 0
      puts "CPU: #{passenger_procs.map { |p| p.split[2].to_f }.sum.round(1)}%"
    end
  end
end

threads.each(&:join)
