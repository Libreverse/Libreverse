# Libreverse XML-RPC API Documentation

This document describes the secure XML-RPC API for Libreverse.

## Overview

The Libreverse API uses XML-RPC over HTTPS for secure, reliable communication. XML-RPC is a remote procedure call protocol which uses XML to encode its calls and HTTP as a transport mechanism.

## Authentication

API access requires authentication through session cookies for most methods. You must obtain a valid session by logging in through the web interface. The session cookie must be included in all API requests that require authentication.

Some methods are available without authentication for public access.

## Endpoint

All XML-RPC calls should be made to the following endpoint:

```http
POST /api/xmlrpc
```

## Security Measures

The API implements multiple security mechanisms:

- All requests must be made over HTTPS
- Rate limiting is enforced to prevent abuse (30 requests per minute per IP)
- Authentication is required for most methods
- Admin role is required for administrative methods
- Input validation is performed on all parameters
- Full audit logging of all API calls
- 3-second processing timeout for all requests

## Available Methods

### Public Methods (No Authentication Required)

#### experiences.all

Retrieves all approved experiences for unauthenticated users, or all experiences for admin users.

**Parameters:** None

**Returns:** Array of experience objects

#### experiences.get

Retrieves a specific experience by ID.

**Parameters:**

- `id` (integer): Experience ID

**Returns:** Experience object or error if not found/accessible

#### experiences.approved

Retrieves all approved experiences.

**Parameters:** None

**Returns:** Array of approved experience objects

#### search.public_query

Searches through approved experiences.

**Parameters:**

- `query` (string): Search query (optional, max 50 characters)
- `limit` (integer): Maximum results to return (optional, default 20, max 100)

**Returns:** Array of matching experience objects

### Authenticated Methods (Session Required)

#### experiences.create

Creates a new experience.

**Parameters:**

- `title` (string): Experience title (required, max 255 characters)
- `description` (string): Experience description (optional, max 2000 characters)
- `html_content` (string): HTML content for the experience (required)
- `author` (string): Author name (optional, defaults to current user's username)

**Returns:** Created experience object

#### experiences.update

Updates an existing experience owned by the current user.

**Parameters:**

- `id` (integer): Experience ID
- `updates` (struct): Object containing fields to update (title, description, author)

**Returns:** Updated experience object

#### experiences.delete

Deletes an experience owned by the current user.

**Parameters:**

- `id` (integer): Experience ID

**Returns:** Success confirmation

#### experiences.pending_approval

Gets experiences pending approval. Admins see all pending experiences, regular users see only their own.

**Parameters:** None

**Returns:** Array of pending experience objects

#### preferences.get

Gets a user preference value.

**Parameters:**

- `key` (string): Preference key (must be from allowed list)

**Returns:** Preference object with key and value

**Allowed preference keys:**

- `dashboard-tutorial`
- `search-tutorial`
- `welcome-message`
- `feature-announcement`
- `theme-selection`
- `sidebar_expanded`
- `sidebar_hovered`
- `drawer_expanded_main`
- `locale`

#### preferences.set

Sets a user preference value.

**Parameters:**

- `key` (string): Preference key (must be from allowed list)
- `value` (string): Preference value

**Returns:** Success confirmation with key and normalized value

#### preferences.dismiss

Marks a preference as dismissed.

**Parameters:**

- `key` (string): Preference key to dismiss

**Returns:** Success confirmation

#### preferences.is_dismissed

Checks if a preference has been dismissed.

**Parameters:**

- `key` (string): Preference key to check

**Returns:** Object with key and dismissed status (boolean)

#### account.get_info

Gets information about the current user account.

**Parameters:** None

**Returns:** Account information object

#### search.query

Searches through experiences. Admins can search all experiences, regular users search only approved ones.

**Parameters:**

- `query` (string): Search query (optional, max 50 characters)
- `limit` (integer): Maximum results to return (optional, default 20, max 100)

**Returns:** Array of matching experience objects

#### moderation.get_logs

Gets moderation logs. Admins see all logs (last 100), regular users see only their own logs.

**Parameters:** None

**Returns:** Array of moderation log objects

### Admin-Only Methods (Admin Role Required)

#### experiences.all_with_unapproved

Gets all experiences including unapproved ones.

**Parameters:** None

**Returns:** Array of all experience objects

#### experiences.approve

Approves an experience.

**Parameters:**

- `id` (integer): Experience ID to approve

**Returns:** Updated experience object

#### admin.experiences.all

Gets all experiences (admin interface).

**Parameters:** None

**Returns:** Array of all experience objects

#### admin.experiences.approve

Approves an experience (admin interface).

**Parameters:**

- `id` (integer): Experience ID to approve

**Returns:** Updated experience object

## Data Structures

### Experience Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>title</name><value><string>Experience Title</string></value></member>
  <member><name>description</name><value><string>Experience description</string></value></member>
  <member><name>author</name><value><string>Author Name</string></value></member>
  <member><name>approved</name><value><boolean>1</boolean></value></member>
  <member><name>account_id</name><value><int>456</int></value></member>
  <member><name>has_html_file</name><value><boolean>1</boolean></value></member>
  <member><name>created_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
  <member><name>updated_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
</struct>
```

### Account Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>username</name><value><string>user123</string></value></member>
  <member><name>admin</name><value><boolean>0</boolean></value></member>
  <member><name>guest</name><value><boolean>0</boolean></value></member>
  <member><name>status</name><value><string>verified</string></value></member>
</struct>
```

### Moderation Log Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>field</name><value><string>title</string></value></member>
  <member><name>model_type</name><value><string>Experience</string></value></member>
  <member><name>content</name><value><string>Flagged content</string></value></member>
  <member><name>reason</name><value><string>inappropriate language</string></value></member>
  <member><name>account_id</name><value><int>456</int></value></member>
  <member><name>violations</name><value><array>...</array></value></member>
  <member><name>created_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
</struct>
```

## Example Requests

### Creating an Experience

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>experiences.create</methodName>
  <params>
    <param><value><string>My Experience Title</string></value></param>
    <param><value><string>A description of my experience</string></value></param>
    <param><value><string>&lt;html&gt;&lt;body&gt;&lt;h1&gt;Hello World&lt;/h1&gt;&lt;/body&gt;&lt;/html&gt;</string></value></param>
    <param><value><string>Author Name</string></value></param>
  </params>
</methodCall>
```

### Getting User Preferences

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.get</methodName>
  <params>
    <param><value><string>dashboard-tutorial</string></value></param>
  </params>
</methodCall>
```

### Searching Experiences

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>search.public_query</methodName>
  <params>
    <param><value><string>tutorial</string></value></param>
    <param><value><int>10</int></value></param>
  </params>
</methodCall>
```

## Error Handling

Errors are returned as XML-RPC fault responses with a fault code and fault string.

**Example error response:**

```xml
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>400</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Invalid preference key</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
```

## Common Fault Codes

- `400`: Bad request (e.g., invalid parameters, missing required fields)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (access denied or insufficient permissions)
- `404`: Method not found
- `408`: Request timeout (processing took longer than 3 seconds)
- `415`: Unsupported content type
- `429`: Rate limit exceeded (more than 30 requests per minute)
- `500`: Internal server error

## Rate Limiting

The API enforces rate limiting of 30 requests per minute per IP address. When the rate limit is exceeded, the API returns a fault response with code 429.

## Client Implementation Examples

See `xmlrpc_client_example.rb` for a complete Ruby client implementation example.
