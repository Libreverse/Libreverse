# frozen_string_literal: true

# ActivityPub extensions for Libreverse-specific metadata
module LibreverseActivityPub
  NAMESPACE = "https://libreverse.org/ns#"

  CUSTOM_FIELDS = {
    "experienceType" => "#{NAMESPACE}experienceType",
    "author" => "#{NAMESPACE}author",
    "approved" => "#{NAMESPACE}approved",
    "htmlContent" => "#{NAMESPACE}htmlContent",
    "searchVector" => "#{NAMESPACE}searchVector",
    "moderationStatus" => "#{NAMESPACE}moderationStatus",
    "interactionCapabilities" => "#{NAMESPACE}interactionCapabilities",
    "instanceDomain" => "#{NAMESPACE}instanceDomain",
    "creatorAccount" => "#{NAMESPACE}creatorAccount",
    "tags" => "#{NAMESPACE}tags"
  }.freeze
end
