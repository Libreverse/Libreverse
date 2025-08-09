#!/usr/bin/env ruby
# frozen_string_literal: true

# Mock test script for parsing Sandbox sitemap using real browser content
# Usage: rails runner scripts/test_sandbox_sitemap.rb

require 'nokogiri'
require 'cgi'

puts "=== Mock Sandbox Sitemap Test ==="
puts "Current time: #{Time.current}"
puts

# Load the mock HTML file from real browser
mock_file_path = Rails.root.join('content-from-real-browser.html')

unless File.exist?(mock_file_path)
  puts "❌ Mock file not found: #{mock_file_path}"
  puts "This file is not committed to version control."
  puts "To test sitemap parsing:"
  puts "  1. Visit https://www.sandbox.game/__sitemap__/experiences.xml in your browser"
  puts "  2. Save the full HTML content to: #{mock_file_path}"
  puts "  3. Run this script again"
  puts
  puts "This script is for development/testing only - the actual indexer will"
  puts "fetch content directly when the Cloudflare issue is resolved."
  exit 0 # Exit gracefully, not as an error
end

puts "=== Loading mock sitemap content ==="
puts "Mock file: #{mock_file_path}"

begin
  html_content = File.read(mock_file_path)
  puts "Content loaded successfully"
  puts "Content length: #{html_content.length} characters"
  puts

  # Parse the content
  puts "=== Parsing content ==="
  doc = Nokogiri::HTML(html_content)

  # Check if this looks like XML sitemap content
  if html_content.include?('<?xml') || html_content.include?('<urlset')
    puts "✅ Got XML sitemap content!"

    # Parse as XML instead of HTML
    xml_doc = Nokogiri::XML(html_content)

    # Look for sitemap index entries
    sitemap_entries = xml_doc.css('sitemap')
    if sitemap_entries.any?
      puts "Found #{sitemap_entries.count} sitemap entries:"
      sitemap_entries.each do |entry|
        loc = entry.at_css('loc')&.text
        puts "  - #{loc}" if loc
      end
    end

    # Look for URL entries
    url_entries = xml_doc.css('url')
    if url_entries.any?
      puts "Found #{url_entries.count} URL entries"

      # Look specifically for experience URLs
      experience_urls = url_entries.select do |entry|
        loc = entry.at_css('loc')&.text
        loc&.include?('/experiences/')
      end

      puts "Experience URLs found: #{experience_urls.count}"

      if experience_urls.count.positive?
        puts "\nFirst 5 experience URLs:"
        i = 0
        while i < [ 5, experience_urls.length ].min
          entry = experience_urls[i]
          loc = entry.at_css('loc')&.text
          puts "  #{i + 1}. #{loc}"

          # Extract title and UUID
          if (match = loc.match(%r{/experiences/([^/]+)/([a-f0-9-]{36})/page}))
            title_encoded = match[1]
            uuid = match[2]
            title = CGI.unescape(title_encoded).gsub('%20', ' ')
            puts "     Title: #{title}"
            puts "     UUID: #{uuid}"
          end
          puts

          i += 1
        end

        puts "Total experience URLs: #{experience_urls.count}"
      end
    end

  else
    puts "✅ Got HTML sitemap content (table format)"

    # Look for the sitemap table
    table = doc.at_css('table#sitemap')
    if table
      puts "Found sitemap table"

      # Get all table rows (skip header)
      rows = table.css('tbody tr')
      puts "Found #{rows.count} table rows"

      if rows.count.positive?
        experience_data = []

        i = 0
        while i < rows.length
          row = rows[i]
          # Get the first cell which contains the experience URL
          url_cell = row.at_css('td:first-child a')

          unless url_cell
            i += 1
            next
          end

          href = url_cell['href']
          unless href&.include?('/experiences/')
            i += 1
            next
          end

          # Extract title and UUID from URL
          unless (match = href.match(%r{/experiences/([^/]+)/([a-f0-9-]{36})/page}))
            i += 1
            next
          end

          title_encoded = match[1]
          uuid = match[2]

          # Decode the title
          title = CGI.unescape(title_encoded)
          # Handle various URL encoding scenarios
          title = title.gsub('%20', ' ').tr('+', ' ')

          experience_data << {
            title: title,
            uuid: uuid,
            url: href,
            row_index: i + 1
          }

          i += 1
        end

        puts "\n=== Parsing Results ==="
        puts "Successfully parsed #{experience_data.count} experiences"

        if experience_data.count.positive?
          puts "\nFirst 5 experiences:"
          i = 0
          while i < [ 5, experience_data.length ].min
            exp = experience_data[i]
            puts "  #{i + 1}. #{exp[:title]}"
            puts "     UUID: #{exp[:uuid]}"
            puts "     URL: #{exp[:url]}"
            puts

            i += 1
          end

          # Check for duplicates
          uuids = experience_data.map { |exp| exp[:uuid] }
          unique_uuids = uuids.uniq
          puts "Total experiences: #{experience_data.count}"
          puts "Unique UUIDs: #{unique_uuids.count}"
          puts "Duplicates: #{experience_data.count - unique_uuids.count}" if unique_uuids.count != experience_data.count

          # Show some title examples
          puts "\nTitle examples:"
          experience_data.sample(5).each do |exp|
            puts "  - '#{exp[:title]}'"
          end
        end
      else
        puts "No table rows found"
      end
    else
      puts "❌ No sitemap table found"

      # Look for experience links anywhere in the HTML
      experience_links = doc.css('a[href*="/experiences/"]')
      puts "Alternative: Found #{experience_links.count} experience links in HTML"

      if experience_links.count.positive?
        puts "\nFirst 5 alternative experience URLs:"
        i = 0
        while i < [ 5, experience_links.length ].min
          link = experience_links[i]
          href = link['href']
          puts "  #{i + 1}. #{href}"

          # Extract title and UUID
          if (match = href.match(%r{/experiences/([^/]+)/([a-f0-9-]{36})/page}))
            title_encoded = match[1]
            uuid = match[2]
            title = CGI.unescape(title_encoded).gsub('%20', ' ')
            puts "     Title: #{title}"
            puts "     UUID: #{uuid}"
          end
          puts

          i += 1
        end
      else
        puts "No experience links found anywhere"

        # Show sample of what we did get
        puts "\nSample content (first 500 chars):"
        puts html_content[0..500]
        puts "..."
      end
    end
  end
rescue StandardError => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end

puts "\n=== Test Complete ==="
