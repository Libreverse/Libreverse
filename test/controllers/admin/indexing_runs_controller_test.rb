# frozen_string_literal: true

require "test_helper"

module Admin
  class IndexingRunsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_indexing_runs_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_indexing_runs_show_url
    assert_response :success
  end
  end
end
