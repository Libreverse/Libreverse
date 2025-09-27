# Ensure CMS public controllers render within the main app layout
Rails.application.config.to_prepare do
  Comfy::Cms::BaseController.layout "application" if defined?(Comfy::Cms::BaseController)
end
