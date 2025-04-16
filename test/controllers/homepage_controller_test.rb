# frozen_string_literal: true

require "test_helper"

class HomepageControllerTest < ActionController::TestCase
  setup do
    # Skip view rendering entirely
    @controller.stubs(:render).returns(nil)
  end

  test "should get index" do
    get :index
    assert_response :success
  end
end
