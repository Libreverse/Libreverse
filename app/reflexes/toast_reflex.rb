class ToastReflex < ApplicationReflex
  include Loggable

  def show(message, type = "info", title = nil)
    # Set default title based on type if not provided
    title ||= case type
    when "success" then "Success"
    when "error" then "Error"
    when "warning" then "Warning"
    else "Information"
    end

    log_info "[ToastReflex#show] Creating toast: #{type} - #{title}"

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
    log_debug "[ToastReflex#show] Adding toast to CableReady queue"
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

    log_info "[ToastReflex#show] Toast broadcast completed"

    # Use nothing morph to avoid conflicting with the CableReady operation
    morph :nothing
  rescue StandardError => e
    log_error "[ToastReflex#show] Error creating toast: #{e.message}", e
    log_error e.backtrace.join("\n")
    morph :nothing
  end
end
