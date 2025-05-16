import { Application } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import StimulusReflex from "stimulus_reflex"

# Start the Stimulus application
app = Application.start()

# Attach ActionCable consumer so StimulusReflex can share the connection
app.consumer = consumer

# Optional debug logging for plain Stimulus (separate from StimulusReflex)
if import.meta.env.MODE is "development"
  app.debug = true
  console.log "StimulusJS Debug Mode Enabled"

globalThis.Stimulus = app

export { app as application }
