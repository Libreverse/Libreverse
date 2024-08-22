require "test_helper"

class WhitepaperControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get whitepaper_index_url
    assert_response :success
  end
end
