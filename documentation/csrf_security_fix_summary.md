# CSRF Security Fix for JSON API

## Issue Description

The JSON API controller had a serious security vulnerability where CSRF protection was completely disabled for all JSON requests using a broad condition:

```ruby
protect_from_forgery with: :exception, unless: -> { valid_json_request? }
```

This exposed all state-changing operations (create, update, delete) to Cross-Site Request Forgery (CSRF) attacks, allowing malicious websites to perform actions on behalf of authenticated users without their consent.

## Security Fix Implementation

### 1. Proper CSRF Protection Strategy

Replaced the vulnerable configuration with a secure approach:

```ruby
# Use null_session for JSON requests to avoid session reset but still protect against CSRF
protect_from_forgery with: :null_session, if: -> { json_request? }
protect_from_forgery with: :exception, unless: -> { json_request? }
```

### 2. State-Changing Method Protection

Added explicit CSRF token verification for state-changing methods:

```ruby
before_action :verify_csrf_for_state_changing_methods
```

### 3. CSRF Token Verification Logic

Implemented granular protection that:

- Allows GET/HEAD/OPTIONS requests without CSRF tokens (safe, idempotent operations)
- Requires valid CSRF tokens for state-changing methods via `X-CSRF-Token` header
- Validates tokens using Rails' built-in `valid_authenticity_token?` method

### 4. Protected Methods

The following state-changing methods now require CSRF tokens:

- `experiences.create`
- `experiences.update`
- `experiences.delete`
- `experiences.approve`
- `preferences.set`
- `preferences.dismiss`
- `admin.experiences.approve`

## Client Implementation

### JavaScript Example

```javascript
// Get CSRF token from meta tag
const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    ?.getAttribute("content");

// Include in request headers for state-changing operations
const response = await fetch("/api/json/experiences.create", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken, // Required for state-changing methods
    },
    body: JSON.stringify({
        title: "My Experience",
        description: "Description",
    }),
});
```

### Error Response

When CSRF token is missing or invalid:

```json
{
    "error": "CSRF token missing or invalid"
}
```

HTTP Status: `403 Forbidden`

## Testing

Added comprehensive tests to verify:

1. State-changing methods require CSRF tokens
2. Valid CSRF tokens allow operations to proceed
3. GET requests work without CSRF tokens
4. Invalid/missing tokens are properly rejected

## Benefits

1. **Security**: Prevents CSRF attacks on state-changing operations
2. **Compatibility**: Maintains backward compatibility for read-only operations
3. **Standards Compliance**: Follows Rails security best practices
4. **Granular Control**: Only protects operations that actually change state

## Migration Notes

Existing clients using the JSON API will need to:

1. Include CSRF tokens for state-changing operations
2. Use the `X-CSRF-Token` header
3. Obtain tokens from Rails' standard meta tag or API endpoint

Read-only operations (GET requests) continue to work without any changes.
