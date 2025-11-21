# frozen_string_literal: true
# shareable_constant_value: literal

# ActivityPub extensions for Libreverse-specific metadata
module LibreverseActivityPub
  NAMESPACE = "https://libreverse.org/ns#"

  CUSTOM_FIELDS = {
    "experienceType" => "#{NAMESPACE}experienceType".freeze,
    "author" => "#{NAMESPACE}author".freeze,
    "approved" => "#{NAMESPACE}approved".freeze,
    "htmlContent" => "#{NAMESPACE}htmlContent".freeze,
    "searchVector" => "#{NAMESPACE}searchVector".freeze,
    "moderationStatus" => "#{NAMESPACE}moderationStatus".freeze,
    "interactionCapabilities" => "#{NAMESPACE}interactionCapabilities".freeze,
    "instanceDomain" => "#{NAMESPACE}instanceDomain".freeze,
    "creatorAccount" => "#{NAMESPACE}creatorAccount".freeze,
    "tags" => "#{NAMESPACE}tags".freeze
  }.freeze
end
