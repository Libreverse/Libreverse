# frozen_string_literal: true

require "test_helper"
require "nokogiri"

module Api
  class XmlrpcControllerTest < ActionController::TestCase
  # Don't use fixtures for this test
  self.use_transactional_tests = true

  setup do
    # Start with a clean slate
    Experience.delete_all

    # Skip certain before_action methods that could cause issues
    @controller.stubs(:validate_method_access).returns(true)
    @controller.stubs(:apply_rate_limit).returns(true)

    # Create two test experiences
    @experience1 = Experience.new(
      title: "Safe Experience One",
      description: "A safe description for the first experience",
      author: "Safe Author One",
      account: accounts(:one),
      approved: true
    )

    # Attach a basic HTML file for first experience
    html_content1 = "<html><body><h1>Safe Experience One</h1></body></html>"
    @experience1.html_file.attach(
      io: StringIO.new(html_content1),
      filename: "safe_experience_1.html",
      content_type: "text/html"
    )

    @experience1.save!

    @experience2 = Experience.new(
      title: "Safe Experience Two",
      description: "A safe description for the second experience",
      author: "Safe Author Two",
      account: accounts(:two),
      approved: true
    )

    # Attach a basic HTML file for second experience
    html_content2 = "<html><body><h1>Safe Experience Two</h1></body></html>"
    @experience2.html_file.attach(
      io: StringIO.new(html_content2),
      filename: "safe_experience_2.html",
      content_type: "text/html"
    )

    @experience2.save!

    # Set the XML content type for all requests
    @request.env["CONTENT_TYPE"] = "text/xml"
  end

  teardown do
    Experience.delete_all
  end

  test "should get all experiences" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.all</methodName>
        <params></params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    experiences = xml_response.xpath("//array/data/value")

    assert_equal 2, experiences.count
  end

  test "should reject deeply nested XML" do
    # Temporarily unstub validate_method_access to allow the method to run
    @controller.unstub(:validate_method_access)

    # Create a deeply nested XML document (more than 100 levels)
    xml_body = "<?xml version=\"1.0\"?>\n<methodCall><methodName>experiences.all</methodName><params>"
    150.times do |i|
      xml_body += "<struct><member><n>level#{i}</n><value>"
    end
    150.times do |_i|
      xml_body += "</value></member></struct>"
    end
    xml_body += "</params></methodCall>"

    post :endpoint, params: { xml: xml_body }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_match(/Invalid XML-RPC request/, fault_string.text)
  end

  test "should reject empty request body" do
    post :endpoint, params: { xml: "" }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_equal "Empty request body", fault_string.text
  end

  test "should reject invalid XML" do
    post :endpoint, params: { xml: "This is not XML" }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_equal "Invalid XML-RPC request", fault_string.text
  end

  test "should reject XML-RPC without method name" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <params>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_match(/No methodName element found/, fault_string.text)
  end
  end
end
