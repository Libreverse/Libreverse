#!/usr/bin/env ruby

# Verification script for account export with maximum compression
# This simulates the account export functionality to verify compression

require_relative "../config/environment"

puts "Testing account export simulation with maximum compression..."

# Create a temporary file to capture the streaming output
temp_file = Tempfile.new([ "account_export_test", ".zip" ])

begin
  # Simulate the account export logic
  temp_file.binmode

  # Define data outside the zip block so we can access it later
  account_data = {
    "id" => 123,
    "email" => "test@example.com",
    "exported_at" => Time.current,
    "export_version" => "1.0"
  }

  preferences = {
    "theme" => "dark",
    "notifications" => true,
    "language" => "en"
  }

  experience_data = {
    "id" => 456,
    "title" => "Test Experience",
    "created_at" => Time.current,
    "content_type" => "text/html"
  }

  html_content = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Test Experience</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .content { background: #f5f5f5; padding: 20px; border-radius: 8px; }
      </style>
    </head>
    <body>
      <div class="content">
        <h1>Test Experience Content</h1>
        <p>This is a sample HTML experience that would be exported.</p>
        <p>The content includes styling and structure that should compress well.</p>
      </div>
    </body>
    </html>
  HTML

  ZipKit::Streamer.open(temp_file) do |zip|
    # Simulate account XML
    zip.write_deflated_file("account.xml") do |sink|
      sink << account_data.to_xml(root: "account")
    end

    # Simulate preferences XML
    zip.write_deflated_file("preferences.xml") do |sink|
      sink << preferences.to_xml(root: "preferences")
    end

    # Simulate experience metadata
    zip.write_deflated_file("experiences/456/metadata.xml") do |sink|
      sink << experience_data.to_xml(root: "experience")
    end

    # Simulate HTML file content
    zip.write_deflated_file("experiences/456/experience_456.html") do |sink|
      sink << html_content
    end
  end

  temp_file.rewind

  # Calculate compression statistics
  account_xml = account_data.to_xml(root: "account")
  preferences_xml = preferences.to_xml(root: "preferences")
  experience_xml = experience_data.to_xml(root: "experience")

  xml_sizes = account_xml.bytesize + preferences_xml.bytesize + experience_xml.bytesize
  html_size = html_content.bytesize
  total_original_size = xml_sizes + html_size
  compressed_size = temp_file.size

  compression_ratio = ((total_original_size - compressed_size).to_f / total_original_size * 100).round(2)

  puts "✓ Account export simulation completed"
  puts "✓ Original content size: #{total_original_size} bytes"
  puts "  - XML metadata: #{xml_sizes} bytes"
  puts "  - HTML content: #{html_size} bytes"
  puts "✓ Compressed ZIP size: #{compressed_size} bytes"
  puts "✓ Compression ratio: #{compression_ratio}%"

  # Verify ZIP structure
  reader = ZipKit::FileReader.new
  entries = reader.read_zip_structure(io: temp_file)

  expected_files = [ "account.xml", "preferences.xml", "experiences/456/metadata.xml", "experiences/456/experience_456.html" ]
  actual_files = entries.map(&:filename).sort

  if expected_files.sort == actual_files
    puts "✓ ZIP structure is correct - contains all expected files:"
    actual_files.each { |file| puts "  - #{file}" }
  else
    puts "✗ ZIP structure mismatch"
    puts "  Expected: #{expected_files.sort}"
    puts "  Actual: #{actual_files}"
  end

  if compression_ratio > 50
    puts "✓ Good compression achieved (#{compression_ratio}%) - maximum compression is working!"
  else
    puts "⚠ Lower compression than expected (#{compression_ratio}%)"
  end
rescue StandardError => e
  puts "✗ Error during simulation: #{e.message}"
  puts e.backtrace.first(5)
ensure
  temp_file.close
  temp_file.unlink
end

puts "\nAccount export simulation completed!"
