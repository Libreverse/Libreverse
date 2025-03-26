# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  def toggle
    # No need to store state, client is handling it with localStorage
    # Just acknowledge the request with morph :nothing
    morph :nothing
  end

  def force_update
    # No need to store state, client is handling it with localStorage
    # Just acknowledge the request with morph :nothing
    morph :nothing
  end
end
