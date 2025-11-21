# frozen_string_literal: true
# shareable_constant_value: literal

json.result do
  json.partial! "api/json/moderation_logs", logs: @logs
end
