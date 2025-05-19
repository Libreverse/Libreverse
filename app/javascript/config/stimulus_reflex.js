import { application } from "../controllers/application";
import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";

// Pass the ActionCable consumer to ensure proper connection handling
application.consumer = consumer;
StimulusReflex.initialize(application, {
    isolate: false, // Set to false to fix issues with authenticated pages
    debug: true, // Keep debugging enabled to help troubleshoot
});

// Development-specific configuration
if (import.meta.env.MODE === "development") {
    StimulusReflex.debug = true;
}
