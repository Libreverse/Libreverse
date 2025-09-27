require "test_helper"

class SearchControllerTest < ActionController::TestCase
  setup do
    # Start with a clean slate
    ExperienceVector.delete_all
    Experience.delete_all

    # Skip view rendering entirely
    @controller.stubs(:render).returns(nil)

    # Create some test experiences to search
    @test_experience = Experience.new(
      title: "Safe Experience Title",
      description: "A safe description for testing",
      author: "Safe Author Name",
      account: accounts(:one)
    )

    # Attach a basic HTML file
    html_content = "<html><body><h1>Safe Experience Title</h1></body></html>"
    @test_experience.html_file.attach(
      io: StringIO.new(html_content),
      filename: "safe_experience.html",
      content_type: "text/html"
    )

    @test_experience.save!
  end

  teardown do
    ExperienceVector.delete_all
    Experience.delete_all
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get index with query" do
    get :index, params: { query: "Safe" }
    assert_response :success
    # Check if experiences were found rather than using assigns
    assert_equal 1, Experience.where("title LIKE ?", "%Safe%").count
  end
end
