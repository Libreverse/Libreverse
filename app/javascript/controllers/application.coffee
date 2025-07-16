{ Application  } = require '@hotwired/stimulus'
consumer = require '../channels/consumer'
StimulusReflex = require 'stimulus_reflex'
# Start the Stimulus application
app = Application.start()

# Attach ActionCable consumer so StimulusReflex can share the connection
app.consumer = consumer

# shut stimulus up
app.debug = false

globalThis.Stimulus = app

module.exports = { app as application  }