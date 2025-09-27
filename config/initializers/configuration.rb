# Configuration loader for YAML configuration files
Rails.application.configure do
    # Load SEO configuration

    seo_config = Rails.application.config_for(:seo_config)
    config.x.seo_config = seo_config
rescue RuntimeError => e
    # Fallback for missing seo_config.yml
    Rails.logger.warn "SEO config not found: #{e.message}"
    config.x.seo_config = {}

  # Indexers configuration is loaded on-demand via config_for(:indexers)
  # No need to preload since it may change and we want fresh config
end
