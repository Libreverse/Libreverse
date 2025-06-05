# frozen_string_literal: true

require "English"
require "etc"

def hardware_threads
  # Platform-specific checks first
  case RUBY_PLATFORM
  when /linux/
    output = `lscpu`
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        return Regexp.last_match(1).to_i if line =~ /^CPU\(s\):\s+(\d+)/
      end
    end
    return File.read("/proc/cpuinfo").scan(/^processor\s*:/).count if File.exist?("/proc/cpuinfo")
  when /darwin/
    output = `sysctl -n hw.ncpu`
    return output.strip.to_i if $CHILD_STATUS.success?
  when /win32|mingw|cygwin/
    output = `wmic cpu get NumberOfLogicalProcessors`
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        return line.strip.to_i if /^\d+/.match?(line)
      end
    end
    return ENV["NUMBER_OF_PROCESSORS"]&.to_i if ENV["NUMBER_OF_PROCESSORS"]
  end

  # Fallback to Etc.nprocessors
  threads = Etc.nprocessors
  return threads if threads.positive?

  # Final fallback to 1 if all else fails
  1
end

if defined?(Iodine)
  # Calculate threads: hardware threads minus 3, but ensure at least 1
  iodine_threads = [ hardware_threads - 3, 1 ].max
  Iodine.threads = iodine_threads
  Iodine.workers = 1
  Iodine::DEFAULT_SETTINGS[:port] ||= ENV.fetch("PORT") { "3000" }
end
