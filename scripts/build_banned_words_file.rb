# frozen_string_literal: true
# shareable_constant_value: literal

require 'httparty'
require 'uri'
require 'yaml'
require 'base64'

# Download the offensive words list
url = 'https://raw.githubusercontent.com/OOPSpam/spam-words/refs/heads/main/spam-words-EN.txt'

puts "Downloading offensive words list from #{url}..."

begin
  response = HTTParty.get(url)

if response.code == 200
    # Validate content before processing
    if response.body.strip.empty?
      puts "Error: Downloaded content is empty"
      exit 1
    end

      # Split the return-separated content into individual words
      words = response.body.split(/\r?\n/).map(&:strip).reject(&:empty?)

     # Validate word content (basic sanity checks)
     words = words.select do |word|
       word.length <= 100 && # Reasonable length limit
         word.match?(/\A[[:print:]]+\z/) && # Only printable characters
         !word.include?('<') && !word.include?('>') # No HTML tags
     end

    if words.empty?
      puts "Error: No valid words found in downloaded content"
      exit 1
    end

    # Create a hash with base64 encoded words
    encoded_words = {}
    index = 0
    while index < words.length
      encoded_words["word_#{index + 1}"] = Base64.strict_encode64(words[index])
      index += 1
    end

    # Convert to YAML
    yaml_content = encoded_words.to_yaml

    # Write to file
    output_file = 'offensive_words_encoded.yml'
    File.write(output_file, yaml_content)

    puts "Successfully created #{output_file} with #{words.length} encoded terms"
    puts "Sample entries:"
    encoded_words.first(3).each do |key, value|
      puts "  #{key}: #{value}"
    end

else
    puts "Failed to download file. HTTP response code: #{response.code}"
end
rescue StandardError => e
  puts "Error occurred: #{e.message}"
end
