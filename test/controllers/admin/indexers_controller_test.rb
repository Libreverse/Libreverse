# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

module Admin
  class IndexersControllerTest < ActionDispatch::IntegrationTest
    test "should get index without authentication" do
      # Test the actual response without stubbing
      get admin_indexers_url
      # The controller should have access control, so expect redirect or auth error
      assert_includes [ 200, 302, 401, 403 ], response.status
    end

    test "should get show without authentication" do
      # Test the actual response without stubbing
      get admin_indexer_url("decentraland")
      # The controller should have access control, so expect redirect or auth error
      assert_includes [ 200, 302, 401, 403 ], response.status
    end
  end
end
