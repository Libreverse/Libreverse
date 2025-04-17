import { application } from "../controllers/application";
import controller from "../controllers/application_controller";
import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";

// Pass the ActionCable consumer to ensure proper connection handling
StimulusReflex.initialize(application, { 
  controller, 
  consumer, 
  isolate: false, // Set to false to fix issues with authenticated pages
  debug: true     // Keep debugging enabled to help troubleshoot
});

// Development-specific configuration
if (import.meta.env.MODE === "development") {
    StimulusReflex.debug = true;
}
