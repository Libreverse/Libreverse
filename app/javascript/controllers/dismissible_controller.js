import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

/**
 * Dismissible Controller
 *
 * This controller handles permanently dismissable elements using server-side storage
 * to remember the user's preference.
 */
export default class extends Controller {
    // This will look for data-dismissible-key-value attribute in HTML
    static values = {
        // Remove 'Value' from the end, Stimulus adds -value suffix automatically
        key: String,
    };

    static targets = ["container"];

    connect() {
        StimulusReflex.register(this);

        // Get the key, checking both patterns we might encounter
        let key;
        if (this.hasKeyValue) {
            // Get key from the controller's value (original pattern)
            key = this.keyValue;
        } else if (this.hasContainerTarget) {
            // Get key from container target (new pattern with parent controller)
            key = this.containerTarget.dataset.dismissibleKeyValue;
        } else {
            // Fallback to the controller element's own dataset
            key = this.element.dataset.dismissibleKeyValue;
        }

        if (key) {
            console.log(`Dismissible controller connected with key: ${key}`);
        } else {
            console.warn(
                "Dismissible controller connected without a key value",
            );
        }
    }

    /**
     * Dismiss the element by triggering the DismissibleReflex
     */
    dismiss(event) {
        // Prevent default behavior if this was called from a button or link
        if (event) event.preventDefault();

        // Get the key, trying all possible sources
        let key;
        if (this.hasKeyValue) {
            // Get key from controller's value (original pattern)
            key = this.keyValue;
        } else if (this.hasContainerTarget) {
            // Get key from container target (new pattern with parent controller)
            key = this.containerTarget.dataset.dismissibleKeyValue;
        } else {
            // Fallback to the controller element's own dataset
            key = this.element.dataset.dismissibleKeyValue;
        }

        if (!key) {
            console.error("Cannot dismiss: No key value provided");
            return;
        }

        console.log(`Dismissing element with key: ${key}`);

        try {
            // Hide the container immediately for better UX
            if (this.hasContainerTarget) {
                this.containerTarget.style.display = "none";
            }

            // Pass the key to the reflex explicitly
            this.stimulate("DismissibleReflex#dismiss", key);
        } catch (error) {
            console.error("Error during dismissal:", error);
        }
    }

    // Lifecycle callbacks
    dismissReflex(element) {
        console.log("Dismissible reflex triggered", element);
    }

    dismissSuccess(element) {
        console.log("Dismissible reflex succeeded", element);
    }

    dismissError(element, error) {
        console.error("Dismissible reflex error", error);
        // If there was an error, restore visibility
        if (this.hasContainerTarget) {
            this.containerTarget.style.display = "";
        }
    }
}
