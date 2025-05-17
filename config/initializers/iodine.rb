# frozen_string_literal: true

if defined?(Iodine)
  Iodine.threads = 1
  Iodine.workers = 1
  Iodine::DEFAULT_SETTINGS[:port] ||= ENV.fetch("PORT", "3000")
end
