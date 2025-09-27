module InvisibleCaptchaHelper
  # Override the invisible_captcha helper to ensure proper HTML structure
  def invisible_captcha(options = {})
    return "".html_safe if Rails.env.test?

    # Generate a random honeypot field name (similar to gem's approach)
    honeypot_name = SecureRandom.hex(6)
    timestamp_name = "invisible_captcha_timestamp"

    # Create container div with multiple hiding techniques to ensure invisibility
    content_tag :div,
                style: "position:absolute!important;top:-9999px;left:-9999px;visibility:hidden;width:0;height:0;overflow:hidden;z-index:-1;",
                'aria-hidden': "true" do
      fields_html = "".html_safe

      # Add honeypot label and field inside the hidden container
      message = options[:sentence_for_humans] ||
                InvisibleCaptcha.sentence_for_humans ||
                "Please leave this field empty"

      fields_html += content_tag(:label,
                                 message,
                                 for: honeypot_name,
                                 style: "display:none!important;position:absolute!important;top:-9999px;left:-9999px;")

      fields_html += text_field_tag(honeypot_name, "",
                                    id: honeypot_name,
                                    autocomplete: "off",
                                    tabindex: -1,
                                    style: "display:none!important;position:absolute!important;top:-9999px;left:-9999px;")

      # Add timestamp field if timestamp is enabled in configuration
      if InvisibleCaptcha.timestamp_enabled
        # Use ISO8601 timestamp string to match invisible_captcha gem expectations
        timestamp_value = Time.current.utc.iso8601
        session[timestamp_name] = timestamp_value if respond_to?(:session)
        fields_html += hidden_field_tag(timestamp_name, timestamp_value, autocomplete: "off")
      end

      fields_html
    end
  end
end
