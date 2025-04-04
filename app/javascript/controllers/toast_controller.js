import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static targets = ["container"];
    static values = {
        autoHide: { type: Boolean, default: true },
        autoHideDelay: { type: Number, default: 5000 },
        timeout: { type: Number, default: 5000 }
    };

    connect() {
        StimulusReflex.register(this);

        // Listen for toast events from the server
        document.addEventListener("toast:created", this.handleToastCreated.bind(this));
        
        // Make the create method available globally
        globalThis.createToast = this.createToast.bind(this);

        // Set up a timer to auto-dismiss the toast
        if (this.timeoutValue > 0) {
            this.dismissTimer = setTimeout(() => {
                this.dismiss();
            }, this.timeoutValue);
        }
    }
    
    disconnect() {
        document.removeEventListener("toast:created", this.handleToastCreated.bind(this));

        // Clean up the timer when the controller is disconnected
        if (this.dismissTimer) {
            clearTimeout(this.dismissTimer);
        }
    }

    handleToastCreated(event) {
        // Show new toasts when they are created
        requestAnimationFrame(() => {
            this.showToasts();
        });

        // You could use this to do something when a toast is created
        // Such as playing a sound or showing a notification badge
        console.log("Toast created:", event.detail);
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
        this.stimulate("ToastReflex#show", message, type, title);
        return true;
    }

    dismiss() {
        // Add animation classes
        this.element.classList.add("opacity-0", "translate-y-2");
        
        // Wait for the animation to complete before removing the element
        setTimeout(() => {
            this.element.remove();
        }, 300);
    }
}
