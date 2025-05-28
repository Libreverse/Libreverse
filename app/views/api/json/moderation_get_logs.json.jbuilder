# frozen_string_literal: true

json.result do
  json.partial! "api/json/moderation_logs", logs: @logs
end
