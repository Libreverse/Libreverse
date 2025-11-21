# frozen_string_literal: true
# shareable_constant_value: literal

json.result do
  json.partial! "api/json/experience_detailed", experience: @experience
end
