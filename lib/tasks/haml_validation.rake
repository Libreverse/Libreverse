# frozen_string_literal: true

namespace :haml do
  desc "Compile all Haml templates to verify syntax"
  task check: :environment do
    require "haml"

    # Collect all .haml files under app/ (including .html.haml)
    files = Dir.glob(Rails.root.join("app/**/*.haml"))

    failed = []

    files.each do |file|
        # Use the parser directly to validate syntax without rendering.
        Haml::Parser.new({}).call(File.read(file))
    rescue Haml::Error => e
        failed << file
        line_no = e.respond_to?(:line) && e.line ? e.line + 1 : nil # Haml::Error stores zero-based index
        header = "\e[31mHAML ERROR in #{file}"
        header << ":#{line_no}" if line_no
        header << "\e[0m"
        puts "#{header} #{e.message}"

        # Print a few lines of context around the error (if we know the line)
        if line_no
          begin
            lines = File.readlines(file, chomp: true)
            start = [ line_no - 3, 0 ].max
            finish = [ line_no + 1, lines.size - 1 ].min
            (start..finish).each do |ln|
              marker = ln + 1 == line_no ? ">>" : "  "
              puts " #{marker} #{format('%4d', ln + 1)} | #{lines[ln]}"
            end
          rescue StandardError
            # If reading file fails, silently ignore context output
          end
        end
    end

    if failed.any?
      abort "\n#{failed.count} Haml file(s) have syntax errors."
    else
      puts "\e[32mAll Haml templates compile cleanly.\e[0m"
    end
  end
end
