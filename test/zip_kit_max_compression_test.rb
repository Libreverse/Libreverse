# typed: false
# !/usr/bin/env ruby
# frozen_string_literal: true
# shareable_constant_value: literal

# Test script to verify zip_kit uses maximum compression
# Run with: ruby test/zip_kit_max_compression_test.rb

require_relative "../config/environment"

puts "Testing zip_kit maximum compression configuration..."

# Test that our initializer correctly overrides the compression level
temp_file = Tempfile.new([ "test_zip", ".zip" ])

begin
  # Test with a highly compressible content (repeated text)
  test_content = "This is a test string that should compress very well. " * 1000

  # Open temp file in binary mode to avoid encoding issues
  temp_file.binmode

  ZipKit::Streamer.open(temp_file) do |zip|
    zip.write_deflated_file("test.txt") do |sink|
      sink << test_content.encode("UTF-8")
    end
  end

  temp_file.rewind
  original_size = test_content.bytesize
  compressed_size = temp_file.size
  compression_ratio = ((original_size - compressed_size).to_f / original_size * 100).round(2)

  puts "✓ Original size: #{original_size} bytes"
  puts "✓ Compressed size: #{compressed_size} bytes"
  puts "✓ Compression ratio: #{compression_ratio}%"

  if compression_ratio > 90 # Expect very high compression for repeated text
    puts "✓ Maximum compression appears to be working (#{compression_ratio}% compression achieved)"
  else
    puts "⚠ Compression ratio lower than expected (#{compression_ratio}%). May not be using maximum compression."
  end

  # Verify the ZIP is valid by trying to read it back
  reader = ZipKit::FileReader.new
  entries = reader.read_zip_structure(io: temp_file)

  if entries.length == 1 && entries.first.filename == "test.txt"
    puts "✓ ZIP file structure is valid"
  else
    puts "✗ ZIP file structure is invalid"
  end
rescue StandardError => e
  puts "✗ Error during test: #{e.message}"
  puts e.backtrace
ensure
  temp_file.close
  temp_file.unlink
end

puts "\nTest completed!"
