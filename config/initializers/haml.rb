# Configure HAML options for Rails templates
# Note: remove_whitespace works in coordination with WhitespaceCompressor middleware
# HAML handles template-level whitespace removal, middleware handles remaining optimization
Haml::Template.options[:remove_whitespace] = true
Haml::Template.options[:format] = :html5
Haml::Template.options[:attr_wrapper] = '"'
Haml::Template.options[:escape_html] = true

# Monkey patch for Turbo-rails compatibility
# This ensures HAML templates default to HTML format for proper Turbo functionality
Rails.application.config.to_prepare do
  if defined?(Haml::Rails::TemplateHandler)
    Haml::Rails::TemplateHandler.class_eval do
      def self.default_format
        :html
      end
    end
  end
end
