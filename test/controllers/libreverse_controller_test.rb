require "test_helper"

class LibreverseControllerTest < ActionDispatch::IntegrationTest
  test "should get picker" do
    get libreverse_picker_url
    assert_response :success
  end
end
