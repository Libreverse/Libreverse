# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class WellKnownController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /.well-known/security.txt
  def security_txt
    # Enhanced cache headers for security.txt - public content with must-revalidate
    set_cache_headers(
      duration: 1.day,
      public: true,
      must_revalidate: true,
      vary: "Accept-Encoding"
    )

    # Set Last-Modified based on instance settings updates
    last_modified_time = InstanceSetting.maximum(:updated_at) || 1.day.ago
    return if check_last_modified(last_modified_time)

    # Get dynamic instance settings with fallbacks
    contacts = build_contact_list
    policy_url = InstanceSetting.get_with_fallback("privacy_policy_url", nil, "/privacy")
    acknowledgements_url = InstanceSetting.get_with_fallback("acknowledgements_url", nil, "/security")
    preferred_languages = InstanceSetting.get_with_fallback("preferred_languages", nil, "en")

    content = <<~TXT
      #{contacts.join("\n")}
      Policy: #{policy_url}
      Preferred-Languages: #{preferred_languages}
      Acknowledgements: #{acknowledgements_url}
      Expires: #{1.year.from_now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
    TXT

    render plain: content, content_type: "text/plain"
  end

  # Serve /.well-known/privacy.txt
  def privacy_txt
    # Enhanced cache headers for privacy.txt - public content with must-revalidate
    set_cache_headers(
      duration: 1.day,
      public: true,
      must_revalidate: true,
      vary: "Accept-Encoding"
    )

    # Set Last-Modified based on instance settings updates
    last_modified_time = InstanceSetting.maximum(:updated_at) || 1.day.ago
    return if check_last_modified(last_modified_time)

    instance_name = InstanceSetting.get_with_fallback("instance_name", nil, "Libreverse Instance")
    policy_url = InstanceSetting.get_with_fallback("privacy_policy_url", nil, "/privacy")

    content = <<~TXT
      This service is operated by #{instance_name}. See our privacy policy at:
      #{policy_url}
    TXT

    render plain: content, content_type: "text/plain"
  end

  private

  def build_contact_list
    contacts = []

    # Signal contact
    signal_url = InstanceSetting.get("security_contact_signal")
    contacts << "Contact: #{signal_url}" if signal_url.present?

    # Email contact
    email = InstanceSetting.get("security_contact_email")
    contacts << "Contact: mailto:#{email}" if email.present?

    # Twitter contact
    twitter = InstanceSetting.get("security_contact_twitter")
    contacts << "Contact: #{twitter}" if twitter.present?

    # Fallback to admin contacts if no security contacts are set
    if contacts.empty?
      admin_signal = InstanceSetting.get("admin_signal_url")
      contacts << "Contact: #{admin_signal}" if admin_signal.present?

      admin_email = InstanceSetting.get("admin_email")
      contacts << "Contact: mailto:#{admin_email}" if admin_email.present?

      admin_twitter = InstanceSetting.get("admin_twitter_handle")
      contacts << "Contact: #{admin_twitter}" if admin_twitter.present?
    end

    # Ultimate fallback to hardcoded values if nothing is configured
    if contacts.empty?
      contacts = [
        "Contact: https://signal.me/#eu/Ui1-KTmlgnCbNj491iq3HSOJtrkY1aVHm4n0v97dvkGDbCqWsExOu66Fzg7-7iC9",
        "Contact: mailto:resists-oysters.0s@icloud.com",
        "Contact: https://x.com/georgebaskervil"
      ]
    end

    contacts
  end
end
