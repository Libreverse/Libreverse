# frozen_string_literal: true

json.result do
  json.partial! "api/json/experiences", experiences: @experiences
end
