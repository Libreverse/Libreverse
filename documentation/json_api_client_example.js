/**
 * Libreverse JSON API Client Example
 *
 * This example demonstrates how to interact with the Libreverse JSON API
 * using JavaScript/Node.js with the fetch API, including CSRF protection.
 */

class LibreverseJsonApiClient {
    constructor(baseUrl = "https://localhost:3000") {
        this.baseUrl = baseUrl;
        this.apiUrl = `${baseUrl}/api/json`;
        this.csrfToken = undefined;
    }

    /**
     * Make a GET request to the API
     */
    async get(method, parameters = {}) {
        const url = new URL(`${this.apiUrl}/${method}`);

        // Add parameters to URL
        for (const key of Object.keys(parameters)) {
            if (parameters[key] !== undefined) {
                url.searchParams.append(key, parameters[key]);
            }
        }

        const response = await fetch(url.toString(), {
            method: "GET",
            credentials: "include", // Include session cookies
            headers: {
                Accept: "application/json",
            },
        });

        return this.handleResponse(response);
    }

    /**
     * Make a POST request to the API with CSRF protection
     */
    async post(method, parameters = {}) {
        // Get CSRF token for state-changing operations
        const headers = {
            "Content-Type": "application/json",
            Accept: "application/json",
        };

        // Add CSRF token for state-changing methods
        const stateChangingMethods = [
            "experiences.create",
            "experiences.update",
            "experiences.delete",
            "experiences.approve",
            "preferences.set",
            "preferences.dismiss",
            "admin.experiences.approve",
        ];

        if (stateChangingMethods.includes(method)) {
            const csrfToken = this.getCSRFToken();
            if (csrfToken) {
                headers["X-CSRF-Token"] = csrfToken;
            }
        }

        const response = await fetch(`${this.apiUrl}/${method}`, {
            method: "POST",
            credentials: "include", // Include session cookies
            headers,
            body: JSON.stringify(parameters),
        });

        return this.handleResponse(response);
    }

    /**
     * Get CSRF token from DOM or stored value
     */
    getCSRFToken() {
        // Try to get from meta tag (Rails default)
        const metaTag = document.querySelector('meta[name="csrf-token"]');
        if (metaTag) {
            return metaTag.getAttribute("content");
        }

        // Fallback: use manually set token
        return this.csrfToken;
    }

    /**
     * Set CSRF token manually if needed
     */
    setCSRFToken(token) {
        this.csrfToken = token;
    }

    /**
     * Handle API response
     */
    async handleResponse(response) {
        const data = await response.json();

        if (response.ok) {
            return data.result;
        } else {
            throw new Error(data.error || "API request failed");
        }
    }

    // === Public Methods (No Authentication Required) ===

    /**
     * Get all approved experiences
     */
    async getAllExperiences() {
        return this.get("experiences.all");
    }

    /**
     * Get a specific experience by ID
     */
    async getExperience(id) {
        return this.get("experiences.get", { id });
    }

    /**
     * Get all approved experiences
     */
    async getApprovedExperiences() {
        return this.get("experiences.approved");
    }

    /**
     * Search through approved experiences
     */
    async searchPublic(query, limit = 20) {
        return this.get("search.public_query", { query, limit });
    }

    // === Authenticated Methods (Session Required) ===

    /**
     * Create a new experience (requires CSRF token)
     */
    async createExperience(title, description, htmlContent, author) {
        return this.post("experiences.create", {
            title,
            description,
            html_content: htmlContent,
            author,
        });
    }

    /**
     * Update an existing experience (requires CSRF token)
     */
    async updateExperience(id, updates) {
        return this.post("experiences.update", {
            id,
            updates,
        });
    }

    /**
     * Delete an experience (requires CSRF token)
     */
    async deleteExperience(id) {
        return this.post("experiences.delete", { id });
    }

    /**
     * Get user preference value
     */
    async getPreference(key) {
        return this.get("preferences.get", { key });
    }

    /**
     * Set user preference value (requires CSRF token)
     */
    async setPreference(key, value) {
        return this.post("preferences.set", { key, value });
    }

    /**
     * Mark preference as dismissed (requires CSRF token)
     */
    async dismissPreference(key) {
        return this.post("preferences.dismiss", { key });
    }

    /**
     * Check if preference is dismissed
     */
    async isPreferenceDismissed(key) {
        return this.get("preferences.is_dismissed", { key });
    }

    /**
     * Get current account information
     */
    async getAccountInfo() {
        return this.get("account.get_info");
    }

    /**
     * Enhanced search (admins see all, users see approved)
     */
    async search(query, limit = 20) {
        return this.get("search.query", { query, limit });
    }

    /**
     * Get moderation logs
     */
    async getModerationLogs() {
        return this.get("moderation.get_logs");
    }

    // === Admin-Only Methods ===

    /**
     * Get all experiences including unapproved (admin only)
     */
    async getAllExperiencesWithUnapproved() {
        return this.get("experiences.all_with_unapproved");
    }

    /**
     * Approve an experience (admin only, requires CSRF token)
     */
    async approveExperience(id) {
        return this.post("experiences.approve", { id });
    }

    /**
     * Get all experiences (admin interface)
     */
    async adminGetAllExperiences() {
        return this.get("admin.experiences.all");
    }

    /**
     * Approve experience (admin interface, requires CSRF token)
     */
    async adminApproveExperience(id) {
        return this.post("admin.experiences.approve", { id });
    }
}

// Export for Node.js
export default LibreverseJsonApiClient;

// Example usage with CSRF token
/*
const client = new LibreverseJsonApiClient('https://yoursite.com');

// Set CSRF token if not available in DOM
client.setCSRFToken('your-csrf-token-here');

// Use the client
client.getAllExperiences().then(experiences => {
  console.log('Experiences:', experiences);
});
*/
