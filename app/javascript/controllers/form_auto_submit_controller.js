import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

// Connects to data-controller="form-auto-submit"
export default class extends Controller {
    static targets = ["form", "input"];
    static values = {
        debounceTime: { type: Number, default: 800 }, // Default to 800ms debounce time
    };

    initialize() {
        this.timer = null;
        this.isSubmitting = false;
    }

    connect() {
        StimulusReflex.register(this);

        // Set up the form
        if (this.hasFormTarget) {
            // Add data attributes for StimulusReflex
            this.formTarget.setAttribute("data-reflex-serialize-form", "true");

            // Ensure form has an ID
            if (!this.formTarget.id) {
                this.formTarget.id = `form-${Math.random().toString(36).substring(2, 10)}`;
            }

            // Create error container if needed
            this.ensureErrorContainer();

            // Listen for the validated event
            this.formTarget.addEventListener(
                "form:validated",
                this.onFormValidated,
            );
        }

        // Monitor input changes
        this.inputTargets.forEach((input) => {
            input.addEventListener("input", this.handleInputChange.bind(this));
        });
    }

    disconnect() {
        // Clean up event listeners
        if (this.hasFormTarget) {
            this.formTarget.removeEventListener(
                "form:validated",
                this.onFormValidated,
            );
        }

        // Clear any pending timers
        if (this.timer) {
            clearTimeout(this.timer);
            this.timer = null;
        }
    }

    // Create error container if needed
    ensureErrorContainer() {
        if (!document.getElementById("form-errors")) {
            const errorDiv = document.createElement("div");
            errorDiv.id = "form-errors";
            errorDiv.className = "form-errors";

            if (this.hasFormTarget) {
                this.formTarget.parentNode.insertBefore(
                    errorDiv,
                    this.formTarget,
                );
            }
        }
    }

    handleInputChange() {
        // Clear any existing timer
        if (this.timer) {
            clearTimeout(this.timer);
        }

        // Set a new timer for debounced validation
        this.timer = setTimeout(
            () => this.validateForm(),
            this.debounceTimeValue,
        );
    }

    validateForm() {
        if (this.isSubmitting) return;

        // Let the server handle validation
        this.stimulate("FormReflex#submit");
    }

    // Arrow function to maintain this context
    onFormValidated = (event) => {
        // Prevent double submission
        if (this.isSubmitting) return;
        this.isSubmitting = true;

        // Submit the form
        setTimeout(() => {
            try {
                this.formTarget.requestSubmit();
            } catch (error) {
                // Fallback for older browsers
                this.formTarget.submit();
            }

            // Reset submission state after a delay
            setTimeout(() => {
                this.isSubmitting = false;
            }, 1000);
        }, 100);
    };
}
