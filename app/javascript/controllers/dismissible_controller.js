import { Controller } from "@hotwired/stimulus";

/**
 * Dismissible Controller
 *
 * This controller handles permanently dismissable elements using server-side storage
 * to remember the user's preference.
 */
export default class extends Controller {
    static values = {
        key: String,
    };

    static targets = ["button"];

    /**
     * When the controller connects, check if this element should be hidden
     * based on whether the user has previously dismissed it.
     */
    connect() {
        // Check server-side on initial load whether this item is dismissed
        this.checkDismissalStatus();
    }

    /**
     * Fetch from the server whether this item has been dismissed
     */
    checkDismissalStatus() {
        fetch(`/api/preferences/is_dismissed?key=${this.keyValue}`, {
            headers: {
                Accept: "application/json",
                "X-Requested-With": "XMLHttpRequest",
            },
        })
            .then((response) => {
                // Check if the response is successful and is JSON
                if (!response.ok) {
                    throw new Error(`Server responded with ${response.status}`);
                }
                // Check Content-Type to ensure it's JSON
                const contentType = response.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    // Handle non-JSON response gracefully
                    console.warn("Non-JSON response received");
                    return { dismissed: false };
                }
                return response.json();
            })
            .then((data) => {
                if (data.dismissed) {
                    this.element.classList.add("dismissed");
                }
            })
            .catch((error) => {
                console.error("Error checking dismissal status:", error);
                // Continue without dismissing - fail gracefully
            });
    }

    /**
     * Dismiss the element by sending a request to store the preference on the server
     * and applying the "dismissed" class to hide it.
     */
    dismiss() {
        // Always apply the dismissed class immediately for better UX
        this.element.classList.add("dismissed");

        // Send the dismissal preference to the server
        fetch("/api/preferences/dismiss", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector(
                    'meta[name="csrf-token"]',
                ).content,
            },
            body: JSON.stringify({ key: this.keyValue }),
        })
            .then((response) => {
                if (!response.ok) {
                    console.error(`Failed to dismiss item: ${response.status}`);
                }
            })
            .catch((error) => {
                console.error("Error during dismiss action:", error);
                // The UI is already updated, so no need to revert
            });
    }
}
