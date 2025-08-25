# Libreverse JSON API Documentation

This document describes the JSON API for Libreverse, providing the same functionality as the XML-RPC API in a modern REST-like JSON format.

## Overview

The Libreverse JSON API provides a clean, modern interface for accessing all application functionality. It supports both GET and POST requests with flexible parameter passing.

## Authentication

API access requires authentication through session cookies for most methods. You must obtain a valid session by logging in through the web interface. The session cookie must be included in all API requests that require authentication.

Some methods are available without authentication for public access.

## Endpoints

The JSON API supports multiple request styles:

### GET Requests with URL Parameters

```http
GET /api/json/{method}?param1=value1&param2=value2
```

### POST Requests with URL Parameters

```http
POST /api/json/{method}
Content-Type: application/json

{
  "param1": "value1",
  "param2": "value2"
}
```

### POST Requests with Method in Body

```http
POST /api/json
Content-Type: application/json

{
  "method": "method.name",
  "param1": "value1",
  "param2": "value2"
}
```

## Security Measures

The API implements multiple security mechanisms:

- All requests should be made over HTTPS in production
- Rate limiting is enforced (60 requests per minute per IP)
- Authentication is required for most methods
- Admin role is required for administrative methods
- Input validation is performed on all parameters
- 3-second processing timeout for all requests
- **CSRF protection**: State-changing methods require a valid CSRF token via `X-CSRF-Token` header
- GET requests (read-only) do not require CSRF tokens

## Response Format

### Success Response

```json
{
    "result": {
        // Method result data
    }
}
```

### Error Response

```json
{
    "error": "Error message"
}
```

## Available Methods

### Public Methods (No Authentication Required)

#### experiences.all

Retrieves all approved experiences for unauthenticated users, or all experiences for admin users.

**GET Example:**

```http
GET /api/json/experiences.all
```

**Response:**

```json
{
    "result": [
        {
            "id": 1,
            "title": "Experience Title",
            "description": "Experience description",
            "author": "Author Name",
            "created_at": "2024-01-01T12:00:00Z",
            "updated_at": "2024-01-01T12:00:00Z"
        }
    ]
}
```

#### experiences.get

Retrieves a specific experience by ID.

**GET Example:**

```http
GET /api/json/experiences.get?id=1
```

**POST Example:**

```http
POST /api/json/experiences.get
Content-Type: application/json

{
  "id": 1
}
```

#### experiences.approved

Retrieves all approved experiences.

**GET Example:**

```http
GET /api/json/experiences.approved
```

#### search.public_query

Searches through approved experiences.

**GET Example:**

```http
GET /api/json/search.public_query?query=tutorial&limit=10
```

**POST Example:**

```http
POST /api/json/search.public_query
Content-Type: application/json

{
  "query": "tutorial",
  "limit": 10
}
```

### Authenticated Methods (Session Required)

#### experiences.create

Creates a new experience.

**POST Example:**

```http
POST /api/json/experiences.create
Content-Type: application/json

{
  "title": "My New Experience",
  "description": "Experience description",
  "html_content": "<html><body><h1>Content</h1></body></html>",
  "author": "Author Name"
}
```

**Response:**

```json
{
    "result": {
        "id": 123,
        "title": "My New Experience",
        "description": "Experience description",
        "author": "Author Name",
        "approved": false,
        "account_id": 456,
        "has_html_file": true,
        "created_at": "2024-01-01T12:00:00Z",
        "updated_at": "2024-01-01T12:00:00Z"
    }
}
```

#### experiences.update

Updates an existing experience owned by the current user.

**POST Example:**

```http
POST /api/json/experiences.update
Content-Type: application/json

{
  "id": 123,
  "updates": {
    "title": "Updated Title",
    "description": "Updated description"
  }
}
```

#### experiences.delete

Deletes an experience owned by the current user.

**POST Example:**

```http
POST /api/json/experiences.delete
Content-Type: application/json

{
  "id": 123
}
```

**Response:**

```json
{
    "result": {
        "success": true,
        "message": "Experience deleted successfully"
    }
}
```

#### preferences.get

Gets a user preference value.

**GET Example:**

```http
GET /api/json/preferences.get?key=dashboard-tutorial
```

**Response:**

```json
{
    "result": {
        "key": "dashboard-tutorial",
        "value": "true"
    }
}
```

#### preferences.set

Sets a user preference value.

**POST Example:**

```http
POST /api/json/preferences.set
Content-Type: application/json

{
  "key": "dashboard-tutorial",
  "value": "false"
}
```

#### preferences.dismiss

Marks a preference as dismissed.

**POST Example:**

```http
POST /api/json/preferences.dismiss
Content-Type: application/json

{
  "key": "welcome-message"
}
```

#### preferences.is_dismissed

Checks if a preference has been dismissed.

**GET Example:**

```http
GET /api/json/preferences.is_dismissed?key=welcome-message
```

#### account.get_info

Gets information about the current user account.

**GET Example:**

```http
GET /api/json/account.get_info
```

**Response:**

```json
{
    "result": {
        "id": 123,
        "username": "user123",
        "admin": false,
        "guest": false,
        "status": "verified"
    }
}
```

#### search.query

Enhanced search - admins can search all experiences, regular users search only approved ones.

**GET Example:**

```http
GET /api/json/search.query?query=tutorial&limit=20
```

#### moderation.get_logs

Gets moderation logs. Admins see all logs, regular users see only their own.

**GET Example:**

```http
GET /api/json/moderation.get_logs
```

### Admin-Only Methods (Admin Role Required)

#### experiences.all_with_unapproved

Gets all experiences including unapproved ones.

**GET Example:**

```http
GET /api/json/experiences.all_with_unapproved
```

#### experiences.approve

Approves an experience.

**POST Example:**

```http
POST /api/json/experiences.approve
Content-Type: application/json

{
  "id": 123
}
```

#### admin.experiences.all

Gets all experiences (admin interface).

**GET Example:**

```http
GET /api/json/admin.experiences.all
```

#### admin.experiences.approve

Approves an experience (admin interface).

**POST Example:**

```http
POST /api/json/admin.experiences.approve
Content-Type: application/json

{
  "id": 123
}
```

## Error Codes

- `400`: Bad request (invalid method name, missing parameters)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (insufficient permissions)
- `408`: Request timeout (processing took longer than 3 seconds)
- `415`: Unsupported content type
- `422`: Unprocessable entity (validation errors)
- `429`: Too many requests (rate limit exceeded)
- `500`: Internal server error

## Rate Limiting

The API enforces rate limiting of 60 requests per minute per IP address. When the rate limit is exceeded, the API returns a 429 status code with an error message.

## Usage Examples

### JavaScript/Fetch API

```javascript
// GET request (no CSRF token required)
async function getAllExperiences() {
    const response = await fetch("/api/json/experiences.all");
    const data = await response.json();
    return data.result;
}

// POST request (CSRF token required for state-changing methods)
async function createExperience(title, description, htmlContent) {
    // Get CSRF token from meta tag or API
    const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        ?.getAttribute("content");

    const response = await fetch("/api/json/experiences.create", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken, // Required for state-changing methods
        },
        body: JSON.stringify({
            title: title,
            description: description,
            html_content: htmlContent,
        }),
    });

    const data = await response.json();
    if (response.ok) {
        return data.result;
    } else {
        throw new Error(data.error);
    }
}

// Search with parameters
async function searchExperiences(query, limit = 20) {
    const response = await fetch(
        `/api/json/search.public_query?query=${encodeURIComponent(query)}&limit=${limit}`,
    );
    const data = await response.json();
    return data.result;
}
```

### cURL Examples

```bash
# GET request
curl -X GET "https://yoursite.com/api/json/experiences.all" \
    -H "Cookie: your_session_cookie"

# POST request
curl -X POST "https://yoursite.com/api/json/experiences.create" \
    -H "Content-Type: application/json" \
    -H "Cookie: your_session_cookie" \
    -d '{
    "title": "My Experience",
    "description": "Test description",
    "html_content": "<html><body>Content</body></html>"
  }'

# Search request
curl -X GET "https://yoursite.com/api/json/search.public_query?query=tutorial&limit=5"
```

### Python Requests

```python
import requests

# GET request
response = requests.get('https://yoursite.com/api/json/experiences.all')
experiences = response.json()['result']

# POST request with authentication
session = requests.Session()
# Set session cookie after login
session.cookies.set('session_cookie_name', 'session_cookie_value')

response = session.post('https://yoursite.com/api/json/experiences.create', json={
    'title': 'My Experience',
    'description': 'Test description',
    'html_content': '<html><body>Content</body></html>'
})

if response.status_code == 200:
    experience = response.json()['result']
else:
    error = response.json()['error']
```

## Comparison with XML-RPC API

The JSON API provides the same functionality as the XML-RPC API but with several advantages:

- **Simpler format**: JSON is more readable and lightweight than XML-RPC
- **Flexible requests**: Supports both GET and POST with multiple parameter styles
- **Better tooling**: Native support in browsers and most programming languages
- **Higher rate limits**: 60 requests/minute vs 30 for XML-RPC
- **Standard HTTP status codes**: Uses proper HTTP status codes for errors

Both APIs provide identical functionality and security features. Choose based on your client requirements and preferences.

## Full JavaScript client example

Below is a complete JavaScript/Node example client for the JSON API.

<!-- markdownlint-disable MD046 -->

```javascript
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
     * Get account info (requires login)
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
```

<!-- markdownlint-enable MD046 -->
