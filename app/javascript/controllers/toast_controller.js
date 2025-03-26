import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static targets = ["container"];
    static values = {
        autoHide: { type: Boolean, default: true },
        autoHideDelay: { type: Number, default: 5000 },
    };

    connect() {
        StimulusReflex.register(this);
        
        // Show toasts immediately when controller connects
        requestAnimationFrame(() => {
            this.showToasts();
        });

        // Make the create method available globally
        globalThis.createToast = this.createToast.bind(this);
    }

    showToasts() {
        const toasts =
            this.containerTarget.querySelectorAll(".toast:not(.show)");

        for (const toast of toasts) {
            // Add show class immediately
            toast.classList.add("show");

            // Auto-hide toast after delay if autoHide is true
            if (this.autoHideValue) {
                setTimeout(() => {
                    this.hideToast(toast);
                }, this.autoHideDelayValue);
            }
        }
    }

    hideToast(toast) {
        toast.classList.remove("show");

        // Remove toast from DOM after animation completes
        setTimeout(() => {
            toast.remove();
        }, 500); // Matches the CSS transition duration
    }

    close(event) {
        const toast = event.target.closest(".toast");
        this.hideToast(toast);
    }

    // Create a new toast using StimulusReflex instead of client-side DOM manipulation
    createToast(message, type = "info", title) {
        this.stimulate("Toast#show", message, type, title);
        return true;
    }
}
