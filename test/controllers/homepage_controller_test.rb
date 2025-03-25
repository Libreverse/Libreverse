require "test_helper"

class HomepageControllerTest < ActionController::TestCase
  setup do
    # Skip view rendering entirely
    @controller.stubs(:render).returns(nil)

    # Mock any methods or objects that the controller needs
    mock_rodauth = Object.new
    def logged_in? = false

    @controller.stubs(:rodauth).returns(mock_rodauth)
  end

  test "should get index" do
    get :index
    assert_response :success
  end
end
