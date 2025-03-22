# Load SEO configuration
SEO_CONFIG = YAML.load_file(Rails.root.join("config/seo_config.yml"), aliases: true)[Rails.env]
