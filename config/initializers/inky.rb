# frozen_string_literal: true
# shareable_constant_value: literal

# Configure Inky for Foundation for Emails templates
require "inky"

ActionView::Template.register_template_handler(:inky, Inky::Rails::TemplateHandler)
