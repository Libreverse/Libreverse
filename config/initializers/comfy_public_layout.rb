# Ensure CMS public controllers render within the main app layout
Rails.application.config.to_prepare do
  if defined?(Comfy::Cms::BaseController)
    Comfy::Cms::BaseController.layout 'application'
  end
end
