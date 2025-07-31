#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test script to verify zip_kit integration works
puts "Testing zip_kit integration..."

require "bundler/setup"
require "zip_kit"
require "zip"
require "tempfile"

# Test 1: Verify zip_kit can create a streaming ZIP with maximum compression
puts "\n1. Testing zip_kit streaming ZIP creation with maximum compression..."
output = StringIO.new
ZipKit::Streamer.open(output) do |zip|
  # Test with deflated files to ensure compression
  zip.write_deflated_file("test.txt") do |sink|
    sink << "Hello from zip_kit streaming with maximum compression!"
  end
  zip.write_deflated_file("data.xml") do |sink|
    sink << "<root><item>test data with compression</item></root>"
  end
end

output.rewind
zip_content = output.string
puts "✓ zip_kit created ZIP of #{zip_content.bytesize} bytes"

# Verify it's a valid ZIP by reading with rubyzip
temp_file = Tempfile.new("test.zip")
temp_file.binmode
temp_file.write(zip_content)
temp_file.close

files_found = []
Zip::File.open(temp_file.path) do |zip_file|
  zip_file.each do |entry|
    files_found << entry.name
    puts "  Found file: #{entry.name} (#{entry.size} bytes)"
  end
end

if files_found.include?("test.txt") && files_found.include?("data.xml")
  puts "✓ zip_kit ZIP verified - contains expected files"
else
  puts "✗ zip_kit ZIP missing expected files"
  exit 1
end

# Test 2: Verify rubyzip still works for email attachments
puts "\n2. Testing rubyzip for email attachments..."
Zip.default_compression = Zlib::BEST_COMPRESSION

zip_buffer = Zip::OutputStream.write_buffer do |zip|
  zip.put_next_entry("email_test.html")
  zip.write("<html><body>Email attachment test</body></html>")
  
  zip.put_next_entry("readme.txt")
  zip.write("This is a test email attachment ZIP")
end

email_zip_content = zip_buffer.string
puts "✓ rubyzip created email ZIP of #{email_zip_content.bytesize} bytes"

# Verify rubyzip content
temp_file2 = Tempfile.new("email_test.zip")
temp_file2.binmode  
temp_file2.write(email_zip_content)
temp_file2.close

email_files_found = []
Zip::File.open(temp_file2.path) do |zip_file|
  zip_file.each do |entry|
    email_files_found << entry.name
    puts "  Found file: #{entry.name} (#{entry.size} bytes)"
  end
end

if email_files_found.include?("email_test.html") && email_files_found.include?("readme.txt")
  puts "✓ rubyzip ZIP verified - contains expected files"
else
  puts "✗ rubyzip ZIP missing expected files"
  exit 1
end

# Test 3: Test ZipKit::RailsStreaming module exists
puts "\n3. Testing ZipKit::RailsStreaming module..."
if defined?(ZipKit::RailsStreaming)
  puts "✓ ZipKit::RailsStreaming module is available"
else
  puts "✗ ZipKit::RailsStreaming module not found"
  exit 1
end

# Cleanup
temp_file.unlink
temp_file2.unlink

puts "\n🎉 All tests passed! zip_kit integration is working correctly."
puts "\nSummary:"
puts "• zip_kit is working for streaming web downloads"
puts "• rubyzip is working for email attachments"
puts "• ZipKit::RailsStreaming is available for Rails controllers"
puts "• Both libraries can coexist in the same application"
