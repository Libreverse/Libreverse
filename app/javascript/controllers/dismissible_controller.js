import { Controller } from "@hotwired/stimulus";
import xmlrpc from "../utils/xmlrpc";

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
     * Dismiss the element by sending an XML-RPC request to store the preference on the server
     * and applying the "dismissed" class to hide it.
     */
    async dismiss() {
        // Always apply the dismissed class immediately for better UX
        this.element.classList.add("dismissed");

        try {
            // Get CSRF token for secure requests
            const csrfToken = document.querySelector(
                'meta[name="csrf-token"]',
            )?.content;

            // Prepare request options
            const options = {
                headers: {
                    "X-CSRF-Token": csrfToken,
                    Accept: "text/xml",
                },
            };

            // Call the XML-RPC method
            await xmlrpc(
                "/api/xmlrpc",
                "preferences.dismiss",
                [this.keyValue],
                options,
            );
            // Success - UI already updated, nothing else to do
        } catch (error) {
            console.error("Error during dismiss action:", error);
            // The UI is already updated, so no need to revert
        }
    }
}
