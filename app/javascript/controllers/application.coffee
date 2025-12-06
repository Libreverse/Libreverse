import { Application } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import StimulusReflex from "stimulus_reflex"

# Start the Stimulus application
app = Application.start()

# Attach ActionCable consumer so StimulusReflex can share the connection
app.consumer = consumer
globalThis.App = { cable: consumer }

# Enable StimulusReflex debug when running in development mode
# Use a safe check compatible with CoffeeScript/Node environments
is_development = false
try
  if typeof process isnt 'undefined' and process.env?
    is_development = process.env.NODE_ENV == 'development'
  else
    # If process isn't available (e.g., in some bundlers), try import.meta if supported
    is_development = (if import.meta? then import.meta.env?.MODE == 'development' else false)
catch error
  is_development = false

if is_development
  StimulusReflex.debug = true
else
  StimulusReflex.debug = false

globalThis.Stimulus = app

export { app as application }
