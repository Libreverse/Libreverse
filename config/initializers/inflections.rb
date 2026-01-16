# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Custom Inflection Rules
# Use this block to add or modify inflection rules per locale.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Example rules (uncomment and customize as needed):
  # inflect.plural /^(ox)$/i, '\\1en'
  # inflect.singular /^(ox)en/i, '\\1'
  # inflect.irregular 'person', 'people'
  # inflect.uncountable %w( fish sheep )
  # inflect.acronym 'RESTful'
end
