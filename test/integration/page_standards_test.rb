# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class PageStandardsTest < ActionDispatch::IntegrationTest
  test "HTML responses use standards mode and allow same-site subresources" do
    expected_corp = Rails.env.development? ? "cross-origin" : "same-site"
    assert_equal expected_corp, Rails.application.config.action_dispatch.default_headers["Cross-Origin-Resource-Policy"]
    assert_equal expected_corp, ActionDispatch::Response.default_headers["Cross-Origin-Resource-Policy"]

    app_layout = Rails.root.join("app/views/layouts/application.slim").read
    admin_layout = Rails.root.join("app/views/layouts/admin.slim").read

    # Slim doctypes like `html` (HTML5) and `strict` (XHTML strict) both trigger standards mode.
    assert_match(/^doctype\s+(html|strict)\b/i, app_layout)
    assert_match(/^doctype\s+(html|strict)\b/i, admin_layout)
  end
end
