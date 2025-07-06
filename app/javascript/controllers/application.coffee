import { Application } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import StimulusReflex from "stimulus_reflex"

# Start the Stimulus application
app = Application.start()

# Attach ActionCable consumer so StimulusReflex can share the connection
app.consumer = consumer

# shut stimulus up
app.debug = false

globalThis.Stimulus = app

export { app as application }
