import { application } from "../controllers/application";
import controller from "../controllers/application_controller";
import StimulusReflex from "stimulus_reflex";

StimulusReflex.initialize(application, { controller, isolate: true });

if (import.meta.env.MODE === "development") {
    StimulusReflex.debug = true;
}
