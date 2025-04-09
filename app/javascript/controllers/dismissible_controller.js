import ApplicationController from "./application_controller";

/**
 * Dismissible Controller
 *
 * This controller handles permanently dismissable elements using server-side storage
 * to remember the user's preference.
 */
export default class extends ApplicationController {
    // This will look for data-dismissible-key-value attribute in HTML
    static values = {
        // Remove 'Value' from the end, Stimulus adds -value suffix automatically
        key: String,
    };

    static targets = ["container"];

    connect() {
        super.connect(); // Call parent connect() to register StimulusReflex
        const key = this.element.dataset.dismissibleKey;
        if (!key) return;

        // Set the data attributes to track the dismissible state
        this.element.dataset.dismissible = "active";

        if (this.element.dataset.autoHide === "true") {
            this.autoHide();
        }
    }

    /**
     * Dismiss the element by triggering the DismissibleReflex
     */
    dismiss(event) {
        if (event) {
            event.preventDefault();
        }

        const key = this.element.dataset.dismissibleKey;
        if (!key) return;

        const element = this.element;

        this.stimulate("DismissibleReflex#dismiss", element);
    }

    // Lifecycle callbacks
    dismissReflex() {
        // Reflex triggered
    }

    dismissSuccess() {
        // Reflex succeeded
    }

    dismissError(element, error) {
        console.error("Dismissible reflex error", error);
        // If there was an error, restore visibility
        if (this.hasContainerTarget) {
            this.containerTarget.style.display = "";
        }
    }
}
