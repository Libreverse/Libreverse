# frozen_string_literal: true

json.result do
  json.partial! "api/json/experience_detailed", experience: @experience
end
