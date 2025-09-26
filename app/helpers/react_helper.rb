# frozen_string_literal: true

module ReactHelper
  # Wrapper for react_component with sensible defaults and optional diagnostics.
  # Usage: = ror_component 'MetaversePreview', props: { name: 'Guest' }
  def ror_component(name, props: {}, **options)
    defaults = {
      props: props,
      prerender: true,
      auto_load_bundle: true,
      trace: Rails.env.development?,
      replay_console: Rails.env.development?,
      logging_on_server: Rails.env.development?,
      raise_on_prerender_error: Rails.env.development?
    }
    react_component(name, **defaults.merge(options))
  end
end
