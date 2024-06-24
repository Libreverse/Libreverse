require "test_helper"

class LibreverseControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get libreverse_index_url
    assert_response :success
  end
end
