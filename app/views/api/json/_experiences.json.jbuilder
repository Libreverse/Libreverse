# frozen_string_literal: true
# shareable_constant_value: literal

json.array! experiences do |experience|
  json.partial! "api/json/experience", experience: experience
end
