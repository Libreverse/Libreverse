# frozen_string_literal: true

class IpAnonymizer
  # Masks IP addresses so logs/controllers see an anonymised value
  # but leaves the original address intact for earlier middleware (Rack::Attack).
  #
  #  - IPv4  -> zeroes the last octet (x.x.x.0)
  #  - IPv6  -> zeroes the last 80 bits (/48 network)
  #
  # Original address is preserved in env['remote_ip_original'] if needed.
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    original_ip = request.remote_ip

    env["remote_ip_original"] = original_ip

    anonymised_ip = self.class.anonymise_ip(original_ip)

    # Expose for downstream consumers
    env["remote_ip_anonymised"] = anonymised_ip

    # Patch the cached ActionDispatch::Request (if any) so subsequent callers
    # – including Rails' log subscribers – see the masked IP.
    if (cached = env["action_dispatch.request"])
      cached.define_singleton_method(:remote_ip) { anonymised_ip }
    end

    # Also update the RemoteIp object Rails stores during processing
    if (remote_ip_obj = env["action_dispatch.remote_ip"])
      begin
        remote_ip_obj.instance_variable_set(:@ip, anonymised_ip)
      rescue StandardError
        nil
      end
    else
      env["action_dispatch.remote_ip"] = anonymised_ip
    end

    @app.call(env)
  end

  def self.anonymise_ip(ip_string)
    require "ipaddr"
    ip = begin
           IPAddr.new(ip_string)
    rescue StandardError
           nil
    end
    return ip_string unless ip

    if ip.ipv4?
      ip.mask(24).to_s
    else
      # Mask everything after /48 (first three 16‑bit blocks)
      ip.mask(48).to_s
    end
  end
end
