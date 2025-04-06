class PageReflex < ApplicationReflex
  def toggle_scroll
    scroll_lock = element.dataset["scroll-lock-lock-value"] == "true"

    # Use the document selector to ensure we always update the html element
    # regardless of where the controller is mounted
    if scroll_lock
      cable_ready.add_css_class(selector: "html", name: "no-scroll")
    else
      cable_ready.remove_css_class(selector: "html", name: "no-scroll")
    end

    cable_ready.broadcast
  end
end
