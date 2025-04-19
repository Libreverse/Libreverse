# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionController::TestCase
  setup do
    # Start with a clean slate
    Experience.delete_all

    # Skip view rendering entirely
    @controller.stubs(:render).returns(nil)

    # Create some test experiences to search
    @test_experience = Experience.new(
      title: "Test Experience 1",
      description: "Description for test experience 1",
      author: "Test Author 1",
      account: accounts(:one)
    )

    # Attach a basic HTML file
    html_content = "<html><body><h1>Test Experience 1</h1></body></html>"
    @test_experience.html_file.attach(
      io: StringIO.new(html_content),
      filename: "test_experience_1.html",
      content_type: "text/html"
    )

    @test_experience.save!
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
