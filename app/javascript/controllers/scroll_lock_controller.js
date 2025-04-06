import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static values = { lock: String };

    initialize() {
        StimulusReflex.register(this);
    }

    connect() {
        // Only stimulate once per page visit
        if (!window._scrollLockStimulated) {
            // Use requestAnimationFrame to ensure DOM is ready
            requestAnimationFrame(() => {
                if (
                    this.element &&
                    document.body.contains(this.element) &&
                    typeof this.stimulate === "function"
                ) {
                    this.stimulate("PageReflex#toggle_scroll", this.element);
                    window._scrollLockStimulated = true;
                }
            });
        }
    }

    lockValueChanged() {
        // Only trigger when lock value actually changes and not from initial connection
        if (window._scrollLockStimulated) {
            requestAnimationFrame(() => {
                if (
                    this.element &&
                    document.body.contains(this.element) &&
                    typeof this.stimulate === "function"
                ) {
                    this.stimulate("PageReflex#toggle_scroll", this.element);
                }
            });
        }
    }
}
