# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CachePreloadJob < ApplicationJob
  queue_as :default

  DEFAULT_MAX_URLS = 200

  def perform(max_urls: DEFAULT_MAX_URLS, rate_limit_ms: 50)
    urls = sitemap_urls(max_urls)

    urls.each do |url|
      HTTParty.get(url, timeout: 10, open_timeout: 10)
      sleep(rate_limit_ms.to_f / 1000.0) if rate_limit_ms.to_i.positive?
    rescue StandardError => e
      Rails.logger.debug "[CachePreloadJob] failed warming #{url}: #{e.class}: #{e.message}"
    end
  end

  private

  def base_url
    Rails.application.routes.default_url_options[:host].presence || "http://localhost:3000"
  end

  def sitemap_urls(max_urls)
    sitemap_url = discover_sitemap_url || "#{base_url}/sitemap.xml"
    response = HTTParty.get(sitemap_url, timeout: 10, open_timeout: 10)
    return [] unless response.code.to_i == 200

    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    doc.xpath("//url/loc").map { |node| node.text.to_s.strip }.reject(&:empty?).first(max_urls.to_i)
  rescue StandardError => e
    Rails.logger.debug "[CachePreloadJob] failed reading sitemap: #{e.class}: #{e.message}"
    []
  end

  def discover_sitemap_url
    robots_url = "#{base_url}/robots.txt"
    response = HTTParty.get(robots_url, timeout: 10, open_timeout: 10)
    return nil unless response.code.to_i == 200

    response.body.to_s.each_line do |line|
      next unless line.strip.downcase.start_with?("sitemap:")

      url = line.split(":", 2).last.to_s.strip
      return url if url.present?
    end

    nil
  rescue StandardError
    nil
  end
end
