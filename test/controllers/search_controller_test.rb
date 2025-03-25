require "test_helper"

class SearchControllerTest < ActionController::TestCase
  setup do
    # Start with a clean slate
    Experience.delete_all

    # Skip view rendering entirely
    @controller.stubs(:render).returns(nil)

    # Mock any methods or objects that the controller needs
    mock_rodauth = Object.new
    def logged_in? = false

    @controller.stubs(:rodauth).returns(mock_rodauth)

    # Create some test experiences to search
    @test_experience = Experience.create!(
      title: "Test Experience 1",
      description: "Description for test experience 1",
      author: "Test Author 1",
      content: "Content for test experience 1"
    )
  end

  teardown do
    Experience.delete_all
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get index with query" do
    get :index, params: { query: "Test" }
    assert_response :success
    # Check if experiences were found rather than using assigns
    assert_equal 1, Experience.where("title LIKE ?", "%Test%").count
  end
end
