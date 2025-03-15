import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input"];
    static values = {
        debounceTime: { type: Number, default: 800 }, // Default to 800ms debounce time
    };

    connect() {
        this.setupFormValidation();
        this.debounceTimer = undefined;
    }

    setupFormValidation() {
        // Add event listeners to all form inputs
        for (const input of this.inputTargets) {
            input.addEventListener("input", this.handleInput.bind(this));
            input.addEventListener("change", this.handleInput.bind(this));
        }
    }

    // New method to handle input with debouncing
    handleInput() {
        // Clear the previous timer
        if (this.debounceTimer) {
            clearTimeout(this.debounceTimer);
        }

        // Set a new timer
        this.debounceTimer = setTimeout(() => {
            this.validateForm();
        }, this.debounceTimeValue);
    }

    validateForm() {
        // Check if the form is valid
        const form = this.element;
        const isValid = form.checkValidity();

        // If all required fields are filled and valid, submit the form
        if (isValid && this.allRequiredFieldsFilled()) {
            // Let Turbo handle the submission
            form.requestSubmit();
        }
    }

    allRequiredFieldsFilled() {
        const requiredInputs = this.inputTargets.filter(
            (input) => input.required,
        );
        return requiredInputs.every((input) => {
            return input.value.trim() !== "";
        });
    }
}
