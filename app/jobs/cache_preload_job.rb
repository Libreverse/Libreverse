# frozen_string_literal: true

require "httparty"
require "nokogiri"
require "zlib"
require "stringio"
require "uri"

class CachePreloadJob < ApplicationJob
    queue_as :maintenance

    # Warms the application caches by crawling the sitemap and requesting each URL.
    # Options:
    #   sitemap_url: override the detected sitemap URL (String)
    #   max_urls: limit number of URLs to warm (Integer)
    #   rate_limit_ms: sleep between requests in milliseconds (Integer)
    def perform(
      sitemap_url: nil,
      max_urls: Integer(ENV.fetch("CACHE_PRELOAD_MAX_URLS") { "1000" }),
      rate_limit_ms: Integer(ENV.fetch("CACHE_PRELOAD_RATE_LIMIT_MS") { "100" })
    )
        base = base_url&.chomp("/")
        return unless base

        sitemap_urls = Array(sitemap_url || discover_sitemaps(base))
        log "Discovered #{sitemap_urls.size} sitemap file(s)"

        urls = Set.new
        sitemap_urls.each do |sm_url|
            urls.merge(fetch_urls_from_sitemap(sm_url))
            break if urls.size >= max_urls
        end

        # Keep only same-origin URLs
        urls = urls.select { |u| same_origin?(base, u) }.take(max_urls)

        log "Warming #{urls.size} URL(s)"
        headers = {
          "User-Agent" => "LibreverseCacheWarmer/1.0 (+https://github.com/Libreverse)"
        }

        size = urls.size
        i = 0
        while i < size
            url = urls[i]
            begin
                HTTParty.get(url, headers:, timeout: 15)
            rescue StandardError => e
                log "ERROR warming #{url}: #{e.class}: #{e.message}"
            end
            # Gentle rate limit to avoid thundering herd
            sleep(rate_limit_ms.to_f / 1000.0) if i < size - 1
            i += 1
        end
    end

  private

    def base_url
        # Prefer SEO config; fall back to ENV
        cfg = begin
                        Rails.application.config_for(:seo_config)
        rescue StandardError
                        nil
        end
        cfg && (cfg["url"] || cfg[:url]) || ENV["APP_BASE_URL"]
    end

    def discover_sitemaps(base)
        robots_url = URI.join("#{base}/", "robots.txt").to_s
        begin
            resp = HTTParty.get(robots_url, timeout: 10)
            if resp.code.to_i == 200
                lines = resp.body.to_s.split(/\r?\n/)
                sitemaps = lines.filter_map do |line|
                    if (m = line.strip.match(/^sitemap:\s*(\S+)/i))
                        m[1]
                    end
                end
                return sitemaps unless sitemaps.empty?
            end
        rescue StandardError => e
            log "robots.txt fetch failed: #{e.class}: #{e.message}"
        end
        # Fallback
        [ URI.join("#{base}/", "sitemap.xml").to_s ]
    end

    def fetch_urls_from_sitemap(url)
        body = fetch_body(url)
        return Set.new unless body

        doc = Nokogiri::XML(body)
        doc.remove_namespaces!

        urls = Set.new
        # If this is an index, follow each child sitemap
        doc.xpath("//sitemap/loc").each do |loc|
            urls.merge(fetch_urls_from_sitemap(loc.text.strip))
        end

        # Otherwise, collect URL entries
        doc.xpath("//url/loc").each do |loc|
            loc_text = loc.text.strip
            urls << loc_text unless loc_text.empty?
        end

        urls
    rescue StandardError => e
        log "ERROR parsing sitemap #{url}: #{e.class}: #{e.message}"
        Set.new
    end

    def fetch_body(url)
        resp = HTTParty.get(url, timeout: 20)
        return unless resp.code.to_i == 200

        body = resp.body

        if url.end_with?(".gz") || resp.headers["content-encoding"].to_s.include?("gzip")
            begin
                gz = Zlib::GzipReader.new(StringIO.new(body))
                return gz.read
            rescue StandardError => e
                log "ERROR decompressing gzip #{url}: #{e.class}: #{e.message}"
                return nil
            end
        end

        body
    rescue StandardError => e
        log "ERROR fetching #{url}: #{e.class}: #{e.message}"
        nil
    end

    def same_origin?(base, other)
        b = URI.parse(base)
        o = URI.parse(other)
        b.scheme == o.scheme && b.host == o.host && (b.port || default_port(b.scheme)) == (o.port || default_port(o.scheme))
    rescue URI::InvalidURIError
        false
    end

    def default_port(scheme)
        scheme == "https" ? 443 : 80
    end

    def log(msg)
        Rails.logger.info("[CachePreloadJob] #{msg}")
    end
end
