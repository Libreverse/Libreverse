# frozen_string_literal: true

require "test_helper"

class EmailHelperTest < ActionView::TestCase
  include EmailHelper

  setup do
    @original_env = Rails.env
  end

  teardown do
    Rails.env = @original_env
  end

  test "inline_email_css works in development" do
    Rails.env = "development"

    # Mock ViteCssFetcher to return test CSS
    ViteCssFetcher.expects(:fetch_css).returns("body { color: red; }")

    result = inline_email_css("~/stylesheets/emails.scss")
    assert_includes result, "color: red"
  end

  test "inline_email_css works in production" do
    Rails.env = "production"

    # Mock ViteRuby manifest to return nil so it falls back to file approach
    vite_instance = mock("vite_instance")
    ViteRuby.expects(:instance).returns(vite_instance).at_least_once
    vite_instance.expects(:manifest).returns(nil).at_least_once

    # Mock file existence and content for the public assets path
    css_file_path = Rails.root.join("public/assets/stylesheets/emails.css")
    File.expects(:exist?).with(css_file_path).returns(true)
    File.expects(:read).with(css_file_path).returns("body { color: blue; }")

    result = inline_email_css("~/stylesheets/emails.scss")
    assert_includes result, "color: blue"
  end

  test "inline_vite_stylesheet works in development" do
    Rails.env = "development"

    ViteCssFetcher.expects(:fetch_css).with("emails.scss").returns("h1 { font-size: 24px; }")

    result = inline_vite_stylesheet("emails.scss")
    assert_equal "h1 { font-size: 24px; }", result
  end

  test "inline_vite_stylesheet works in production" do
    Rails.env = "production"

    # Mock ActionController helper
    ActionController::Base.helpers.expects(:asset_path).with("emails.scss").returns("/assets/emails-abc123.css")

    # Mock file operations
    File.expects(:exist?).returns(true)
    File.expects(:read).returns("h1 { font-size: 24px; }")

    result = inline_vite_stylesheet("emails.scss")
    assert_equal "h1 { font-size: 24px; }", result
  end

  test "inline_vite_stylesheet handles missing files gracefully" do
    Rails.env = "production"

    ActionController::Base.helpers.expects(:asset_path).returns("/assets/missing.css")
    File.expects(:exist?).returns(false)

    result = inline_vite_stylesheet("missing.scss")
    assert_equal "", result
  end
end
