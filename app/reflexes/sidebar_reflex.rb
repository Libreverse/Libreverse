# frozen_string_literal: true

class SidebarReflex < ApplicationReflex
  # Simple reflex that does nothing but acknowledge the hover state change
  def toggle_hover
    # No need to store state, client is handling it with localStorage
    # Just acknowledge the request with morph :nothing
    morph :nothing
  end
end
