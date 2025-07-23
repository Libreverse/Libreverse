# frozen_string_literal: true

require "test_helper"

module Admin
  class IndexersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_indexers_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_indexers_show_url
    assert_response :success
  end
  end
end
