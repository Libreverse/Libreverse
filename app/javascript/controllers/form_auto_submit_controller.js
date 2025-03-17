import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="form-auto-submit"
export default class extends Controller {
    static targets = ["form", "input"];
    static values = {
        debounceTime: { type: Number, default: 800 }, // Default to 800ms debounce time
        minPasswordLength: { type: Number, default: 12 }
    };

    initialize() {
        this.debounce = this.debounce.bind(this);
        this.timer = null;
    }

    connect() {
        // Monitor input changes
        this.inputTargets.forEach(input => {
            input.addEventListener("input", this.handleInputChange.bind(this));
        });
    }

    disconnect() {
        if (this.timer) {
            clearTimeout(this.timer);
        }
    }

    handleInputChange(event) {
        // Clear any existing timer
        if (this.timer) {
            clearTimeout(this.timer);
        }
        
        // Set a new timer
        this.timer = setTimeout(() => this.checkFormReadiness(), this.debounceTimeValue);
    }

    checkFormReadiness() {
        // Get all required inputs and check if they're filled
        const requiredInputs = this.inputTargets.filter(input => input.required);
        const allRequiredFilled = requiredInputs.every(input => input.value.trim() !== "");
        
        // If we have password fields, check password requirements
        const passwordInputs = this.inputTargets.filter(input => 
            (input.id === "password" || input.id === "new-password") && !input.id.includes("confirm")
        );
        
        const passwordsValid = passwordInputs.every(input => 
            !input.required || input.value.length >= this.minPasswordLengthValue
        );
        
        // Check password confirmation matches if present
        let confirmationValid = true;
        const passwordConfirmInputs = this.inputTargets.filter(input => 
            input.id.includes("confirm")
        );
        
        if (passwordConfirmInputs.length > 0) {
            passwordConfirmInputs.forEach(confirmInput => {
                const mainPasswordId = confirmInput.id.replace("-confirm", "");
                const mainPassword = document.getElementById(mainPasswordId);
                if (mainPassword && confirmInput.required) {
                    confirmationValid = confirmationValid && (confirmInput.value === mainPassword.value);
                }
            });
        }
        
        // If all conditions are met, submit the form
        if (allRequiredFilled && passwordsValid && confirmationValid) {
            this.submitForm();
        }
    }
    
    submitForm() {
        this.formTarget.requestSubmit();
    }
    
    // Utility function to debounce input
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
}
