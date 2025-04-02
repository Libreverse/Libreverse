import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

// Connects to data-controller="form-auto-submit"
export default class extends Controller {
    static targets = ["form", "input"];
    static values = {
        debounceTime: { type: Number, default: 800 }, // Default to 800ms debounce time
        minPasswordLength: { type: Number, default: 12 },
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

        // Perform basic client-side validation
        if (this.isFormValid()) {
            try {
                // Trigger the reflex - use the simplest form possible
                this.stimulate("FormReflex#submit");
            } catch (error) {
                console.error("Error triggering form validation:", error);
            }
        }
    }

    isFormValid() {
        let valid = true;
        let errors = [];

        // Check required fields
        this.inputTargets.forEach((input) => {
            if (input.required && input.value.trim() === "") {
                valid = false;
                errors.push(`${input.name || 'Field'} is required`);
            }

            // Basic password validation
            if (
                (input.type === "password") &&
                input.required &&
                input.value.length < this.minPasswordLengthValue
            ) {
                valid = false;
                errors.push(`Password must be at least ${this.minPasswordLengthValue} characters`);
            }
            
            // Validate email format if it's an email field
            if (
                input.type === "email" && 
                input.value.trim() !== "" && 
                !this.isValidEmail(input.value)
            ) {
                valid = false;
                errors.push("Email format is invalid");
            }
            
            // Prevent XSS in text inputs
            if (input.type === "text" || input.type === "textarea") {
                // Check for potential XSS content
                if (/<script|javascript:|on\w+\s*=|data:/i.test(input.value)) {
                    valid = false;
                    errors.push("Invalid characters detected");
                    // Clear the potentially malicious input
                    input.value = "";
                }
            }
        });

        // Display errors if present
        if (!valid && errors.length > 0) {
            this.displayErrors(errors);
        } else {
            this.clearErrors();
        }

        return valid;
    }

    // Helper for email validation
    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // Display form errors
    displayErrors(errors) {
        const errorContainer = document.getElementById("form-errors");
        if (errorContainer) {
            errorContainer.innerHTML = "";
            const errorList = document.createElement("ul");
            errorList.className = "error-list";
            
            errors.forEach(error => {
                const errorItem = document.createElement("li");
                errorItem.textContent = error;
                errorList.appendChild(errorItem);
            });
            
            errorContainer.appendChild(errorList);
        }
    }

    // Clear form errors
    clearErrors() {
        const errorContainer = document.getElementById("form-errors");
        if (errorContainer) {
            errorContainer.innerHTML = "";
        }
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
