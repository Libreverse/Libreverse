# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class PagesController < ApplicationController
  include HighVoltage::StaticPage

  skip_before_action :_enforce_privacy_consent

  class << self
    def page_cache
      @page_cache ||= {}
    end

    def page_cache_mutex
      @page_cache_mutex ||= Mutex.new
    end
  end

  def show
    return super if Rails.env.development?

    # Legal pages should not be cached by clients/proxies; only cache in-process.
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    key = [params[:id], I18n.locale.to_s].join(":")
    rendered = self.class.page_cache[key]

    unless rendered
      html = render_to_string(template: "pages/#{params[:id]}", layout: "application")
      self.class.page_cache_mutex.synchronize do
        self.class.page_cache[key] ||= html
      end
      rendered = self.class.page_cache[key]
    end

    render html: rendered.html_safe, layout: false
  end
end
