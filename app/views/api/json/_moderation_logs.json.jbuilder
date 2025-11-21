# frozen_string_literal: true
# shareable_constant_value: literal

json.array! logs do |log|
  json.partial! "api/json/moderation_log", log: log
end
