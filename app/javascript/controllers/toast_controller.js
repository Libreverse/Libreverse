import { Controller } from "@hotwired/stimulus";

// This controller is attached directly to individual toast elements.
// It handles auto-hiding and manual dismissal for that specific toast.
export default class extends Controller {
    static values = {
        // Timeout in milliseconds before auto-hiding. 0 disables auto-hide.
        timeout: { type: Number, default: 5000 }
    };

    connect() {
        // Start hidden, then transition to visible
        this.element.style.opacity = 0;
        // Use requestAnimationFrame to ensure the transition applies after initial render
        requestAnimationFrame(() => {
            this.element.style.opacity = 1;
            this.element.style.transform = 'translateY(0)'; // Assuming initial CSS might have it translated
        });

        // Set up a timer to auto-dismiss the toast if timeout is positive
        if (this.timeoutValue > 0) {
            this.dismissTimer = setTimeout(() => {
                this.dismiss();
            }, this.timeoutValue);
        }
    }

    disconnect() {
        // Clean up the timer when the controller is disconnected (e.g., element removed)
        if (this.dismissTimer) {
            clearTimeout(this.dismissTimer);
        }
    }

    // Action method called by the close button (data-action="toast#dismiss")
    dismiss() {
        // Prevent multiple dismiss calls if already dismissing
        if (this.isDismissing) return;
        this.isDismissing = true;

        // Clear the auto-hide timer if it exists
        if (this.dismissTimer) {
            clearTimeout(this.dismissTimer);
        }

        // Add animation classes/styles for fade-out/slide-up
        this.element.style.opacity = 0;
        this.element.style.transform = 'translateY(-10px)'; // Example: slide up slightly
        // Use transitionend event for more robust removal, but setTimeout is simpler here

        // Wait for the animation (defined in CSS transition) to complete before removing the element
        // Ensure this timeout matches your CSS transition duration for opacity/transform
        setTimeout(() => {
            this.element.remove();
        }, 300); // Assuming a 300ms transition in CSS
    }
}
