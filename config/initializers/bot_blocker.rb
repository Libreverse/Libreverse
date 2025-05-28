# frozen_string_literal: true

# Bot Blocker Middleware Configuration
# This middleware uses voight-kampff to detect and block bots when no_bots_mode is enabled

require_relative "../../lib/middleware/bot_blocker"

# Add the middleware to the Rails application configuration
# This approach works in all environments
Rails.application.config.middleware.use BotBlocker 