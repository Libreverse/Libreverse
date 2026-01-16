# typed: false
#!/usr/bin/env ruby
# frozen_string_literal: true
# shareable_constant_value: literal

require 'fileutils'
require 'open3'
require 'rbconfig'

# Copies a macOS libmimalloc.dylib into ./mimalloc so Electron packaging can bundle it.
#
# Usage:
#   ruby scripts/prepare_mimalloc.rb            # best-effort
#   ruby scripts/prepare_mimalloc.rb --required # fail if not available

required = ARGV.include?('--required')

host = RbConfig::CONFIG['host_os']
unless /darwin/i.match?(host)
  puts '[mimalloc] non-macOS host; nothing to do.'
  exit 0
end

repo_root = File.expand_path('..', __dir__)
out_dir = File.join(repo_root, 'mimalloc')
out_lib = File.join(out_dir, 'libmimalloc.dylib')

FileUtils.mkdir_p(out_dir)

source_lib = ENV['MIMALLOC_SOURCE_LIB']

if source_lib.nil? || source_lib.strip.empty?
  brew = `command -v brew`.strip
  if brew.empty?
    msg = '[mimalloc] Homebrew not found; cannot locate libmimalloc.dylib. Install mimalloc via brew or set MIMALLOC_SOURCE_LIB.'
    warn msg
    exit(required ? 1 : 0)
  end

  stdout, status = Open3.capture2(brew, '--prefix', 'mimalloc')
  unless status.success?
    msg = '[mimalloc] Homebrew package "mimalloc" not installed; run: brew install mimalloc (or set MIMALLOC_SOURCE_LIB).'
    warn msg
    exit(required ? 1 : 0)
  end

  prefix = stdout.strip
  candidate = File.join(prefix, 'lib', 'libmimalloc.dylib')
  source_lib = candidate
end

unless File.file?(source_lib)
  msg = "[mimalloc] lib not found at: #{source_lib.inspect} (set MIMALLOC_SOURCE_LIB to an existing .dylib)"
  warn msg
  exit(required ? 1 : 0)
end

# Avoid rewriting if unchanged
begin
  if File.file?(out_lib) && File.size(out_lib) == File.size(source_lib)
    # Not perfect, but good enough (avoids extra work during packaging)
    puts "[mimalloc] already staged: #{out_lib}"
    exit 0
  end
rescue StandardError
  # proceed with copy
end

FileUtils.cp(source_lib, out_lib, preserve: true)
puts "[mimalloc] staged #{source_lib} -> #{out_lib}"
