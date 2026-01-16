# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class LanguagePickerReflex < ApplicationReflex
  # List of locales that require right-to-left direction.
  RTL_LOCALES = %w[ar he fa ur].freeze

  def select(locale)
    locale = locale.to_s
    Rails.logger.info "[LanguagePickerReflex] select called with locale: #{locale}"
    Rails.logger.info "[LanguagePickerReflex] current_account.id: #{current_account&.id}"

    if I18n.available_locales.map(&:to_s).include?(locale)
      # Persist locale in session and immediately switch I18n on the server
      session[:locale] = locale
      I18n.locale = locale

      # Persist user preference when possible
      if current_account&.id
        Rails.logger.info "[LanguagePickerReflex] Attempting to set locale preference for account #{current_account.id} to: #{locale}"
        UserPreference.set(current_account.id, "locale", locale)
      else
        Rails.logger.info "[LanguagePickerReflex] Not setting locale preference: current_account or current_account.id is nil."
      end
    else
      Rails.logger.warn "[LanguagePickerReflex] Invalid locale selected: #{locale}"
    end

    # Determine text direction based on the chosen locale
    direction = RTL_LOCALES.include?(locale) ? "rtl" : "ltr"

    # Update <html> attributes without a full-page reload so the UI can flip
    cable_ready
      .redirect_to(url: controller.request.path)
      .set_attribute(selector: "html", name: "dir", value: direction)
      .set_attribute(selector: "html", name: "lang", value: locale)
      .dispatch_event(name: "language:changed", detail: { locale: locale, dir: direction })
      .broadcast

    # Suppress StimulusReflex default page morph – no additional HTML needed
    morph :nothing
  end
end
