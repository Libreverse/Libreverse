Sentry.init do |config|
  config.dsn = 'https://3ff68d31dcdf415b8904a05b75fdc7b1@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/7'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
end