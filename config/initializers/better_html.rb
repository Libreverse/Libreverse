# frozen_string_literal: true
# shareable_constant_value: literal

require "better_html"

# Configure BetterHtml using the repo-level YAML if present; otherwise keep defaults.
# This enables HTML-aware ERB parsing and runtime validations for .html.erb templates.

begin
  yaml_path = Rails.root.join(".better-html.yml")
  if File.exist?(yaml_path)
    require "yaml"
    BetterHtml.config = BetterHtml::Config.new(
      YAML.load_file(yaml_path, permitted_classes: [ Regexp ])
    )
  else
    BetterHtml.configure do |config|
      # Keep defaults; override examples:
      # config.allow_single_quoted_attributes = false
    end
  end

  # Example: enable BetterHtml for additional content types, if desired.
  # impl = BetterHtml::BetterErb.content_types['html.erb']
  # BetterHtml::BetterErb.content_types['html+variant.erb'] = impl
rescue NameError
  # BetterHtml not loaded yet; initializer will be evaluated after gems load in production.
  # In development, ensure the gem is installed and bundle is up-to-date.
end
