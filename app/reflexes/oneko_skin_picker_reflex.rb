# frozen_string_literal: true
# shareable_constant_value: literal

class OnekoSkinPickerReflex < ApplicationReflex
  def select(skin)
    skin = skin.to_s
    Rails.logger.info "[OnekoSkinPickerReflex] select called with skin: #{skin}"

    # List of available skins
    available_skins = %w[
      ace agender asexual bisexual black bunny calico eevee esmeralda fox gay genderfluid ghost gray jess kina lesbian lucy maia maria mike nonbinary oneko_black oneko_gray oneko onekoslvt pride silver silversky snuupy spirit tora trans valentine
    ]

    if available_skins.include?(skin) || skin == "default"
      # Persist user preference
      if current_account&.id
        Rails.logger.info "[OnekoSkinPickerReflex] Setting oneko-skin preference for account #{current_account.id} to: #{skin}"
        UserPreference.set(current_account.id, "oneko-skin", skin)
      end

      # Broadcast the change to update the UI
      cable_ready
        .redirect_to(url: controller.request.path)
        .dispatch_event(name: "oneko:skin-changed", detail: { skin: skin })
        .broadcast

    else
      Rails.logger.warn "[OnekoSkinPickerReflex] Invalid skin selected: #{skin}"
    end
morph :nothing
  end
end
