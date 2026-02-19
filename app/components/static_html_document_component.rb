# typed: true
# frozen_string_literal: true

class StaticHtmlDocumentComponent < Phlex::HTML
  def initialize(html:)
    super()
    @html = html
  end

  def view_template
    unsafe_raw(@html)
  end
end
