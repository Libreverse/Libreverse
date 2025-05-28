# frozen_string_literal: true

json.array! logs do |log|
  json.partial! "api/json/moderation_log", log: log
end
