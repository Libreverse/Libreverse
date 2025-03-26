# frozen_string_literal: true

class DrawerReflex < ApplicationReflex
  def toggle
    # Toggle the drawer state in the session
    session[:drawer_expanded] = !session[:drawer_expanded]
    is_expanded = session[:drawer_expanded]

    # Update drawer classes based on the expanded state
    operations = cable_ready
    
    # Handle each class based on the state
    if is_expanded
      operations.add_css_class(selector: ".drawer", name: "drawer-expanded")
      operations.add_css_class(selector: ".drawer-icons", name: "rotated")
      operations.add_css_class(selector: ".drawer-contents", name: "visible")
      operations.add_css_class(selector: "body", name: "drawer-is-expanded")
    else
      operations.remove_css_class(selector: ".drawer", name: "drawer-expanded")
      operations.remove_css_class(selector: ".drawer-icons", name: "rotated")
      operations.remove_css_class(selector: ".drawer-contents", name: "visible")
      operations.remove_css_class(selector: "body", name: "drawer-is-expanded")
    end

    operations.broadcast
  end

  # Alternative method that can be used if class toggling doesn't work properly
  def force_update
    # Set the drawer state in the session
    session[:drawer_expanded] = !session[:drawer_expanded]
    is_expanded = session[:drawer_expanded]
    
    # Apply classes directly via attributes
    cable_ready
      .set_attribute(
        selector: ".drawer",
        name: "class",
        value: is_expanded ? "drawer drawer-expanded" : "drawer"
      )
      .set_attribute(
        selector: ".drawer-icons",
        name: "class", 
        value: is_expanded ? "drawer-icons rotated" : "drawer-icons"
      )
      .set_attribute(
        selector: ".drawer-contents",
        name: "class",
        value: is_expanded ? "drawer-contents visible" : "drawer-contents"
      )
      .set_attribute(
        selector: "body",
        name: "class",
        value: is_expanded ? "drawer-is-expanded" : ""
      )
      .broadcast
  end
end
