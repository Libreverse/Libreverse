# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  # Patch all relevant ActiveStorage controllers to set strict private download headers
  [
    defined?(ActiveStorage::Blobs::ProxyController) && ActiveStorage::Blobs::ProxyController,
    defined?(ActiveStorage::Blobs::RedirectController) && ActiveStorage::Blobs::RedirectController,
    defined?(ActiveStorage::Representations::ProxyController) && ActiveStorage::Representations::ProxyController,
    defined?(ActiveStorage::Representations::RedirectController) && ActiveStorage::Representations::RedirectController,
    defined?(ActiveStorage::DiskController) && ActiveStorage::DiskController
  ].compact.each do |controller|
    controller.class_eval do
      actions = %i[show download].select { |a| action_methods.include?(a.to_s) }
      after_action only: actions do
        response.headers["Cache-Control"] = "private, max-age=0"
      end
    end
  end
end
