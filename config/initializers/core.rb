# Core Application Configuration
# This file contains essential application initializations:
# - Bootsnap performance optimization
# - Inflection rules
# - Error tracking (Sentry)
# - SEO configuration

# ===== Bootsnap Performance Optimization =====
require "bootsnap"
env = ENV["RAILS_ENV"] || "development"
Bootsnap.setup(
  cache_dir: "tmp/cache", # Path to your cache
  ignore_directories: [ "node_modules" ], # Directory names to skip.
  development_mode: env == "development", # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
  load_path_cache: true, # Optimize the LOAD_PATH with a cache
  compile_cache_iseq: true,                 # Compile Ruby code into ISeq cache, breaks coverage reporting.
  compile_cache_yaml: true,                 # Compile YAML into a cache
  compile_cache_json: true,                 # Compile JSON into a cache
  readonly: true # Use the caches but don't update them on miss or stale entries.
)

# ===== Inflection Rules =====
# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# ===== Error Tracking (Sentry) =====
Sentry.init do |config|
  config.dsn =
    "https://3ff68d31dcdf415b8904a05b75fdc7b1@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/7"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
end

# ===== SEO Configuration =====
# Load SEO configuration
SEO_CONFIG = YAML.load_file(Rails.root.join("config/seo_config.yml"), aliases: true)[Rails.env]
