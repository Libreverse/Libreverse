# frozen_string_literal: true

require "test_helper"

class ViteCssFetcherTest < ActiveSupport::TestCase
  test "fetch_css extracts CSS from JavaScript response" do
    # Mock the HTTP response with CSS embedded in JavaScript
    js_response = <<~JS
      import "/app/stylesheets/foundation-emails.scss";
      const css = "body { color: red; } .button { background: blue; }";
      export default css;
    JS

    Net::HTTP.expects(:get_response).returns(mock(code: "200", body: js_response))

    result = ViteCssFetcher.fetch_css("emails.scss")
    assert_includes result, "color: red"
    assert_includes result, "background: blue"
  end

  test "fetch_css handles direct CSS response" do
    css_response = "body { margin: 0; } h1 { font-size: 24px; }"

    Net::HTTP.expects(:get_response).returns(mock(code: "200", body: css_response))

    result = ViteCssFetcher.fetch_css("emails.css")
    assert_equal css_response, result
  end

  test "fetch_css handles network errors gracefully" do
    Net::HTTP.expects(:get_response).raises(StandardError.new("Network error"))

    result = ViteCssFetcher.fetch_css("emails.scss")
    assert_equal "", result
  end

  test "fetch_css handles 404 responses" do
    Net::HTTP.expects(:get_response).returns(mock(code: "404", body: "Not Found"))

    result = ViteCssFetcher.fetch_css("missing.scss")
    assert_equal "", result
  end

  test "fetch_css builds correct Vite dev server URL" do
    expected_url = "http://localhost:5173/app/stylesheets/emails.scss"

    Net::HTTP.expects(:get_response).with do |uri|
      uri.to_s == expected_url
    end.returns(mock(code: "200", body: "body { color: green; }"))

    ViteCssFetcher.fetch_css("emails.scss")
  end
end
