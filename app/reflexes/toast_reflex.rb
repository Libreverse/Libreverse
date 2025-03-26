class ToastReflex < ApplicationReflex
  def show(message, type = "info", title = nil)
    # Set default title based on type if not provided
    unless title
      title = case type
              when "success" then "Success"
              when "error" then "Error"
              when "warning" then "Warning"
              else "Information"
              end
    end

    # Render the toast partial
    html = render_to_string(
      partial: "shared/toast",
      locals: {
        message: message,
        type: type,
        title: title
      }
    )

    # Broadcast to the client using CableReady
    cable_ready.append(
      selector: "#toast-container",
      html: html
    ).broadcast
  end
end 