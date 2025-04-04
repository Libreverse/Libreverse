class ToastReflex < ApplicationReflex
  def show(message, type = "info", title = nil)
    # Set default title based on type if not provided
    title ||= case type
    when "success" then "Success"
    when "error" then "Error"
    when "warning" then "Warning"
    else "Information"
    end

    # Render the toast partial
    html = render_to_string(
      partial: "layouts/toast",
      locals: {
        message: message,
        type: type,
        title: title
      }
    )

    # Broadcast to the client using CableReady
    cable_ready
      .append(
        selector: "#toast-container",
        html: html
      )
      .dispatch_event(
        name: "toast:created",
        detail: { type: type, title: title }
      )
      .broadcast
      
    # Use nothing morph to avoid conflicting with the CableReady operation
    morph :nothing
  end
end
