class OnekoSkinPickerReflex < ApplicationReflex
  def select(skin)
    skin = skin.to_s
    Rails.logger.info "[OnekoSkinPickerReflex] select called with skin: #{skin}"

    # List of available skins
    available_skins = %w[
      default black gray spirit asexual silver trans valentine fox maia mike pride bisexual genderfluid silversky esmeralda jess calico agender snuupy lesbian maria kina eevee onekoslvt bunny gay lucy nonbinary ace tora ghost
    ]

    if available_skins.include?(skin) || skin == 'default'
      # Persist user preference
      if current_account&.id
        Rails.logger.info "[OnekoSkinPickerReflex] Setting oneko-skin preference for account #{current_account.id} to: #{skin}"
        UserPreference.set(current_account.id, "oneko-skin", skin)
      end

      # Broadcast the change to update the UI
      cable_ready
        .dispatch_event(name: "oneko:skin-changed", detail: { skin: skin })
        .broadcast

      morph :nothing
    else
      Rails.logger.warn "[OnekoSkinPickerReflex] Invalid skin selected: #{skin}"
      morph :nothing
    end
  end
end