# frozen_string_literal: true
# shareable_constant_value: literal

require "shellwords"

desc "Run ERB lint"
task erb_lint: :environment do
  sh "bundle exec erblint --config .erb-lint.yml app/views"
end

namespace :erb do
  desc "Format ERB templates in place"
  task format: :environment do
    files = Dir.glob("app/**/*.erb", File::FNM_EXTGLOB)
               .reject { |p| p == "app/views/layouts/mailer.html.erb" }
    unless files.empty?
      cmd = [
        "bundle", "exec", "erb-format", "--write",
        *files.map { |f| Shellwords.escape(f) }
      ].join(" ")
      sh cmd
    end
  end
end
