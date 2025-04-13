import { Application } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

const app = Application.start();

// Attach consumer to the Stimulus application instance
app.consumer = consumer;

// Configure Stimulus development experience
if (import.meta.env.MODE === "development") {
    app.debug = true;
    console.log("StimulusJS Debug Mode Enabled");
}
globalThis.Stimulus = app;

export { app as application };
