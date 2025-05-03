# frozen_string_literal: true

module Emoji
  module Renderer
    module_function

    require "cgi"
    require "erb"
    require "digest/sha1"
    require "uri"
    require "net/http"

    # Matches standard emojis, including sequences with ZWJ and skin tone modifiers. Note that it's an exception to the general re2 use rule as the identifiers it needs aren't supported by RE2.
    EMOJI_REGEX = /(?:\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?(?:\u{200D}\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

    DEFAULT_CACHE_EXPIRY = 1.week

    # Public: Replaces any emoji characters found in +input+ with inline SVG <img> tags.
    # Returns the processed String (not HTML-safe).
    def replace(input, cache_expiry: DEFAULT_CACHE_EXPIRY)
      str = input.to_s
      Rails.logger.debug { "[Emoji::Renderer] replace called – length=#{str.bytesize}" }

      return input unless str.match?(EMOJI_REGEX)

      str.gsub(EMOJI_REGEX) do |emoji|
        key = cache_key(emoji)
        stored = Rails.cache.read(key)
        cache_hit = !stored.nil?
        Rails.logger.debug { "[Emoji::Renderer] Processing emoji='#{emoji}' (key=#{key}) – cache_hit=#{cache_hit}" }

        tag = stored

        if tag.blank?
          Rails.logger.debug { "[Emoji::Renderer] Cache MISS or empty value for emoji='#{emoji}'. Building img tag…" }
          tag = build_img_tag(emoji)

          if tag.present?
            Rails.cache.write(key, tag, expires_in: cache_expiry)
            Rails.logger.debug { "[Emoji::Renderer] Stored img tag in cache for emoji='#{emoji}'" }
          else
            # Ensure we don't keep nil sentinel in cache
            Rails.cache.delete(key) if cache_hit
            Rails.logger.debug { "[Emoji::Renderer] No SVG tag generated for emoji='#{emoji}'. Leaving original character." }
          end
        end

        tag.presence || emoji
      end
    end

    # Public: Builds the inline SVG <img> tag for a given +emoji+ character.
    # Returns the String markup or nil if the underlying SVG file could not be found.
    def build_img_tag(emoji)
      Rails.logger.debug { "[Emoji::Renderer] build_img_tag called for emoji='#{emoji}'" }
      svg_content = fetch_svg_for_emoji(emoji)
      return nil if svg_content.blank?

      Rails.logger.debug { "[Emoji::Renderer] SVG content length=#{svg_content.bytesize} for emoji='#{emoji}'" }
      encoded_svg = ERB::Util.url_encode(svg_content)
      %(<img src="data:image/svg+xml,#{encoded_svg}" alt="#{CGI.escapeHTML(emoji)}" class="emoji" loading="eager" decoding="async" fetchpriority="low" draggable="false" tabindex="-1">)
    rescue StandardError => e
      Rails.logger.error "Emoji::Renderer#build_img_tag – #{e.class}: #{e.message}"
      nil
    end

    # Internal: Computes a Rails-cache compatible key for an emoji.
    def cache_key(emoji)
      key = "emoji_renderer/v1/#{Digest::SHA1.hexdigest(emoji)}"
      Rails.logger.debug { "[Emoji::Renderer] Generated cache key=#{key} for emoji='#{emoji}'" }
      key
    end

    # Internal: Retrieves the raw SVG markup for +emoji+ from Vite's manifest/asset pipeline.
    # Handles both dev-server (HTTP) and production (static file) scenarios.
    def fetch_svg_for_emoji(emoji)
      Rails.logger.debug { "[Emoji::Renderer] fetch_svg_for_emoji called for emoji='#{emoji}'" }
      codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")
      Rails.logger.debug { "[Emoji::Renderer] Codepoints string='#{codepoints}'" }

      svg_path = nil
      begin
        svg_path = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg", type: :image)
        Rails.logger.debug { "[Emoji::Renderer] Manifest path='#{svg_path}'" }
        content = read_vite_asset_content(svg_path)
        return content if content.present?
      rescue ViteRuby::MissingEntrypointError => e
        Rails.logger.debug { "[Emoji::Renderer] manifest lookup failed: #{e.message}" }
      end

      # Fallback for dev/test: read directly from app/emoji
      dev_fallback_path = Rails.root.join("app/emoji", "#{codepoints}.svg")
      if File.exist?(dev_fallback_path)
        Rails.logger.debug { "[Emoji::Renderer] Using dev fallback SVG at '#{dev_fallback_path}'" }
        return File.read(dev_fallback_path)
      end

      Rails.logger.warn { "[Emoji::Renderer] SVG file not found for emoji #{emoji.inspect} (#{codepoints})" }
      nil
    end

    # Internal: Reads the file referenced by +manifest_path+ respecting the current environment.
    def read_vite_asset_content(manifest_path)
      Rails.logger.debug { "[Emoji::Renderer] read_vite_asset_content path='#{manifest_path}'" }
      return if manifest_path.blank?

      if Rails.env.development? || Rails.env.test?
        dev_uri = URI.join(ViteRuby.instance.config.public_base_url, manifest_path)
        Rails.logger.debug { "[Emoji::Renderer] Fetching from dev server URI=#{dev_uri}" }
        Net::HTTP.get(dev_uri)
      else
        relative = manifest_path.sub(%r{^/?#{ViteRuby.instance.config.public_output_dir}/}, "")
        file_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, relative)
        Rails.logger.debug { "[Emoji::Renderer] Reading precompiled asset at '#{file_path}'" }
        File.exist?(file_path) ? File.read(file_path) : nil
      end
    rescue StandardError => e
      Rails.logger.error "Emoji::Renderer#read_vite_asset_content – #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
      nil
    end
  end
end
