# frozen_string_literal: true

# The ActionCable logger is REALLY noisy, and might even impact performance.
# Uncomment the line below to silence the ActionCable logger.

# ActionCable.server.config.logger = Logger.new(nil)

StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail:
  # `:exit` or `:warn` or `:ignore`
  #
  # config.on_failed_sanity_checks = :exit

  # Enable/disable exiting / warning when there is no default URLs specified in environment config
  # `:warn` or `:ignore`
  #
  # config.on_missing_default_urls = :warn

  # Enable/disable assets compilation
  # `true` or `false`
  #
  # config.precompile_assets = true

  # Override the CableReady operation used for morphing and replacing content
  #
  # config.morph_operation = :morph
  # config.replace_operation = :inner_html

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
  #
  # config.parent_channel = "ApplicationCable::Channel"

  # Override the logger that the StimulusReflex uses; default is Rails' logger
  # eg. Logger.new(RAILS_ROOT + "/log/reflex.log")
  #
  # config.logger = Rails.logger

  # Customize server-side Reflex logging format, with optional colorization:
  # Available tokens: session_id, session_id_full, reflex_info, operation, id, id_full, mode, selector, operation_counter, connection_id, connection_id_full, timestamp
  # Available colors: red, green, yellow, blue, magenta, cyan, white
  # You can also use attributes from your ActionCable Connection's identifiers that resolve to valid ActiveRecord models
  # eg. if your connection is `identified_by :current_user` and your User model has an email attribute, you can access r.email (it will display `-` if the user isn't logged in)
  # Learn more at: https://docs.stimulusreflex.com/appendices/troubleshooting#stimulusreflex-logging
  #
  # config.logging = proc { "[#{session_id}] #{operation_counter.magenta} #{reflex_info.green} -> #{selector.cyan} via #{mode} Morph (#{operation.yellow})" }

  # Optimized for speed, StimulusReflex doesn't enable Rack middleware by default.
  # If you are using Page Morphs and your app uses Rack middleware to rewrite part of the request path, you must enable those middleware modules in StimulusReflex.
  #
  # Learn more about registering Rack middleware in Rails here: https://guides.rubyonrails.org/rails_on_rack.html#configuring-middleware-stack
  #
  # config.middleware.use FirstRackMiddleware
  # config.middleware.use SecondRackMiddleware
  # this option set is from the default readme of htmlcompressor
  config.middleware.use HtmlCompressor::Rack,
    enabled: true,
    remove_spaces_inside_tags: true,
    remove_multi_spaces: true,
    remove_comments: true,
    remove_intertag_spaces: false,
    remove_quotes: false,
    compress_css: false,
    compress_javascript: false,
    simple_doctype: false,
    remove_script_attributes: false,
    remove_style_attributes: false,
    remove_link_attributes: false,
    remove_form_attributes: false,
    remove_input_attributes: false,
    remove_javascript_protocol: false,
    remove_http_protocol: false,
    remove_https_protocol: false,
    preserve_line_breaks: false,
    simple_boolean_attributes: false,
    compress_js_templates: false

  # We insert the emoji middleware here so that it precedes
  # the html minifier but still avoids unnecessary work
  # It does not work in this situation for some currenrly unknown reason, so it is disabled
  # config.middleware.use EmojiReplacer
end
