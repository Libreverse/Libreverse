import { application } from "../controllers/application";
import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";

// Pass the ActionCable consumer to ensure proper connection handling
application.consumer = consumer;
StimulusReflex.initialize(application, {
    isolate: true, // Explicitly enable isolation mode (will be the default in next version)
});

// Development-specific configuration
if (import.meta.env.MODE === "development") {
    StimulusReflex.debug = true;
}
else {
    StimulusReflex.debug = false;
}