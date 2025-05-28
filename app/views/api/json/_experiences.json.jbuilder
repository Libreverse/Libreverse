# frozen_string_literal: true

json.array! experiences do |experience|
  json.partial! "api/json/experience", experience: experience
end
