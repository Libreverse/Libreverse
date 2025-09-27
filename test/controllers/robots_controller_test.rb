require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "serves allow all robots.txt when no_bots_mode is disabled" do
    InstanceSetting.set("no_bots_mode", "false")

    get "/robots.txt"

    assert_response :success
    assert_match %r{text/plain}, response.content_type
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Disallow:"
    assert_not_includes response.body, "Disallow: /"
  end

  test "serves disallow all robots.txt when no_bots_mode is enabled" do
    InstanceSetting.set("no_bots_mode", "true")

    get "/robots.txt"

    assert_response :success
    assert_match %r{text/plain}, response.content_type
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Disallow: /"
  end

  test "defaults to allow all when no_bots_mode setting is missing" do
    # Ensure the setting doesn't exist
    setting = InstanceSetting.find_by(key: "no_bots_mode")
    setting&.destroy

    get "/robots.txt"

    assert_response :success
    assert_match %r{text/plain}, response.content_type
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Disallow:"
    assert_not_includes response.body, "Disallow: /"
  end

  test "handles various truthy values for no_bots_mode" do
    %w[true 1 yes on enabled].each do |value|
      InstanceSetting.set("no_bots_mode", value)

      get "/robots.txt"

      assert_response :success
      assert_includes response.body, "Disallow: /", "Failed for value: #{value}"
    end
  end

  test "handles various falsy values for no_bots_mode" do
    %w[false 0 no off disabled].each do |value|
      InstanceSetting.set("no_bots_mode", value)

      get "/robots.txt"

      assert_response :success
      assert_includes response.body, "Disallow:"
      assert_not_includes response.body, "Disallow: /", "Failed for value: #{value}"
    end
  end
end
