# frozen_string_literal: true

desc 'Run ERB lint'
task :erb_lint do
  sh 'bundle exec erblint --config .erb-lint.yml app/views'
end

namespace :erb do
  desc 'Format ERB templates in place'
  task :format do
    sh 'bundle exec erb-format app/views/**/*.erb --write'
  end
end
