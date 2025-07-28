#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs i18n-tasks autofix (normalize, remove-unused, add-missing) and validation (health)
require 'open3'

def run_cmd(desc, cmd)
  puts "\n=== #{desc} ==="
  stdout, stderr, status = Open3.capture3(*cmd)
  puts stdout
  warn stderr unless stderr.empty?
  return if status.success?

    puts "#{desc} failed."
    exit 1
end

run_cmd('Normalizing translations', %w[bundle exec i18n-tasks normalize])
run_cmd('Removing unused keys', %w[bundle exec i18n-tasks remove-unused])
run_cmd('Adding missing keys with placeholders', %w[bundle exec i18n-tasks add-missing])
run_cmd('i18n health check', %w[bundle exec i18n-tasks health])

puts "\ni18n validation and autofix complete."
