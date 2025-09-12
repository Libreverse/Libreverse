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
# Remove unused keys non-interactively to avoid HighLine confirmation in non-TTY
# Equivalent to: i18n-tasks unused -f yaml | i18n-tasks data-remove
puts "\n=== Removing unused keys ==="
unused_yaml_stdout, unused_yaml_stderr, = Open3.capture3(*%w[bundle exec i18n-tasks unused -f yaml])
puts unused_yaml_stderr unless unused_yaml_stderr.empty?

# i18n-tasks sometimes prints a banner line that breaks YAML; strip it out.
sanitized_yaml = unused_yaml_stdout.lines.reject { |l| l.strip.start_with?('#StandWithUkraine') }.join

if sanitized_yaml.strip.empty?
  puts 'No unused keys detected.'
else
  remove_stdout, remove_stderr, remove_status = Open3.capture3(*%w[bundle exec i18n-tasks data-remove], stdin_data: sanitized_yaml)
  puts remove_stdout
  warn remove_stderr unless remove_stderr.empty?
  unless remove_status.success?
    puts 'Removing unused keys failed.'
    exit 1
  end
end

run_cmd('Adding missing keys with placeholders', %w[bundle exec i18n-tasks add-missing])
run_cmd('i18n health check', %w[bundle exec i18n-tasks health])

puts "\ni18n validation and autofix complete."
