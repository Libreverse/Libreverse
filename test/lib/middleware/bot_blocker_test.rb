# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/middleware/bot_blocker"

class BotBlockerTest < ActiveSupport::TestCase
  def setup
    @app = ->(_env) { [ 200, {}, [ "OK" ] ] }
    @middleware = BotBlocker.new(@app)
  end

  test "allows normal requests when no_bots_mode is disabled" do
    InstanceSetting.set("no_bots_mode", "false")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end

  test "allows normal requests when no_bots_mode is enabled" do
    InstanceSetting.set("no_bots_mode", "true")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end

  test "blocks bot requests when no_bots_mode is enabled" do
    InstanceSetting.set("no_bots_mode", "true")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "HTTP_USER_AGENT" => "Googlebot/2.1 (+http://www.google.com/bot.html)",
      "REMOTE_ADDR" => "127.0.0.1"
    }

    status, headers, body = @middleware.call(env)
    assert_equal 403, status
    assert_equal "text/plain", headers["Content-Type"]
    assert_equal [ "Forbidden" ], body
  end

  test "allows bot requests when no_bots_mode is disabled" do
    InstanceSetting.set("no_bots_mode", "false")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "HTTP_USER_AGENT" => "Googlebot/2.1 (+http://www.google.com/bot.html)"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end

  test "always allows robots.txt requests" do
    InstanceSetting.set("no_bots_mode", "true")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/robots.txt",
      "HTTP_USER_AGENT" => "Googlebot/2.1 (+http://www.google.com/bot.html)"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end

  test "always allows admin routes" do
    InstanceSetting.set("no_bots_mode", "true")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/admin/instance_settings",
      "HTTP_USER_AGENT" => "Googlebot/2.1 (+http://www.google.com/bot.html)"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end

  test "always allows well-known routes" do
    InstanceSetting.set("no_bots_mode", "true")

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/.well-known/security.txt",
      "HTTP_USER_AGENT" => "Googlebot/2.1 (+http://www.google.com/bot.html)"
    }

    status, _headers, _body = @middleware.call(env)
    assert_equal 200, status
  end
end
