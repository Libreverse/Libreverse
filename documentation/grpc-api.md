# Libreverse gRPC API Documentation

This document describes the gRPC API for Libreverse, providing both native gRPC and HTTP-based access to the same functionality as the XML-RPC API.

## Overview

The Libreverse gRPC API provides type-safe, efficient remote procedure calls using Protocol Buffers (protobuf) for serialization. It offers two access methods:

1. **Native gRPC**: Direct gRPC connections for maximum performance and type safety
2. **HTTP-based gRPC**: JSON over HTTP for easier integration from web applications

## Integration (server)

The gRPC server runs inside the Rails process for simplicity and shared state:

- Starts with Rails (background thread)
- Default host/port: 127.0.0.1:50051 (config via `GRPC_HOST`, `GRPC_PORT`)
- SSL in production (via `GRPC_SSL_CERT_PATH`, `GRPC_SSL_KEY_PATH`)
- Rate limiting and auth aligned with XML-RPC

Development:

```bash
# Start web + gRPC together
bin/dev
```

HTTP bridge:

```javascript
await fetch("/api/grpc", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ method: "GetAllExperiences", request: {} }) })
```

## Authentication

Similar to the XML-RPC API, authentication is handled through:

- Session cookies for web-based access
- Session IDs passed in headers or metadata
- Bearer tokens (if implemented in your auth system)

### Native gRPC Authentication

For native gRPC calls, pass authentication metadata:

```ruby
metadata = { "session-id" => "your_session_id" }
client.get_all_experiences(request, metadata: metadata)
```

### HTTP-based gRPC Authentication

For HTTP-based calls, use headers:

```bash
curl -X POST https://localhost:3000/api/grpc \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: your_session_id" \
    -d '{"method": "GetAllExperiences", "request": {}}'
```

## Endpoints

### Native gRPC Server

- **Host**: `localhost:50051` (configurable via `GRPC_PORT` environment variable)
- **Protocol**: gRPC over HTTP/2

### HTTP-based gRPC Endpoint

- **URL**: `POST /api/grpc`
- **Content-Type**: `application/json`

## Security Measures

The gRPC API implements the same security measures as the XML-RPC API:

- TLS encryption for production (configure appropriate credentials)
- Rate limiting (30 requests per minute per IP)
- Authentication required for most methods
- Admin role required for administrative methods
- Input validation on all parameters
- Full audit logging of all API calls

## Available Methods

### Experience Management

#### GetAllExperiences

Retrieves all approved experiences for unauthenticated users, or all experiences for admin users.

**Request**: `GetAllExperiencesRequest` (empty)
**Response**: `ExperiencesResponse` containing array of experiences

#### GetExperience

Retrieves a specific experience by ID.

**Request**: `GetExperienceRequest`

- `id` (int32): Experience ID

**Response**: `ExperienceResponse` containing the experience

#### CreateExperience

Creates a new experience (requires authentication).

**Request**: `CreateExperienceRequest`

- `title` (string): Experience title
- `description` (string): Experience description
- `author` (string): Author name

**Response**: `ExperienceResponse` containing the created experience

#### UpdateExperience

Updates an existing experience owned by the authenticated user.

**Request**: `UpdateExperienceRequest`

- `id` (int32): Experience ID
- `title` (optional string): New title
- `description` (optional string): New description
- `author` (optional string): New author

**Response**: `ExperienceResponse` containing the updated experience

#### DeleteExperience

Deletes an experience owned by the authenticated user.

**Request**: `DeleteExperienceRequest`

- `id` (int32): Experience ID

**Response**: `DeleteResponse` with success status

#### ApproveExperience

Approves an experience owned by the authenticated user.

**Request**: `ApproveExperienceRequest`

- `id` (int32): Experience ID

**Response**: `ExperienceResponse` containing the approved experience

#### GetPendingExperiences

Retrieves all pending (unapproved) experiences for the authenticated user.

**Request**: `GetPendingExperiencesRequest` (empty)
**Response**: `ExperiencesResponse` containing array of pending experiences

### User Preferences

#### GetPreference

Retrieves a user preference value.

**Request**: `GetPreferenceRequest`

- `key` (string): Preference key

**Response**: `PreferenceResponse` containing the preference value

#### SetPreference

Sets a user preference value.

**Request**: `SetPreferenceRequest`

- `key` (string): Preference key
- `value` (string): Preference value

**Response**: `PreferenceResponse` containing the set preference

#### DismissPreference

Dismisses a user preference.

**Request**: `DismissPreferenceRequest`

- `key` (string): Preference key

**Response**: `PreferenceResponse` containing the dismissed preference

### Administrative Methods

#### AdminApproveExperience

Approves any experience (requires admin role).

**Request**: `AdminApproveExperienceRequest`

- `id` (int32): Experience ID

**Response**: `ExperienceResponse` containing the approved experience

## Data Types

### Experience

```protobuf
message Experience {
  int32 id = 1;
  string title = 2;
  string description = 3;
  string author = 4;
  bool approved = 5;
  string created_at = 6;
  string updated_at = 7;
  int32 account_id = 8;
}
```

### Error Handling

gRPC uses standard status codes:

- `OK (0)`: Success
- `INVALID_ARGUMENT (3)`: Invalid request parameters
- `UNAUTHENTICATED (16)`: Authentication required
- `PERMISSION_DENIED (7)`: Insufficient permissions
- `NOT_FOUND (5)`: Resource not found
- `INTERNAL (13)`: Internal server error

For HTTP-based gRPC, these are mapped to appropriate HTTP status codes.

## Client Examples

### Ruby Native gRPC Client

```ruby
require 'grpc'
require_relative 'libreverse_pb'
require_relative 'libreverse_services_pb'

# Connect to gRPC server
stub = Libreverse::Grpc::LibreverseService::Stub.new(
  'localhost:50051',
  :this_channel_is_insecure
)

# Get all experiences
request = Libreverse::Grpc::GetAllExperiencesRequest.new
response = stub.get_all_experiences(request)
puts response.experiences
```

### HTTP-based gRPC with curl

```bash
# Get all experiences
curl -X POST https://localhost:3000/api/grpc \
    -H "Content-Type: application/json" \
    -d '{"method": "GetAllExperiences", "request": {}}'

# Create experience
curl -X POST https://localhost:3000/api/grpc \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: your_session_id" \
    -d '{
    "method": "CreateExperience",
    "request": {
      "title": "My Experience",
      "description": "Description here",
      "author": "Author Name"
    }
  }'
```

### JavaScript/Node.js Example

```javascript
const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");

// Load protobuf
const packageDefinition = protoLoader.loadSync("libreverse.proto");
const libreverse = grpc.loadPackageDefinition(packageDefinition).libreverse;

// Create client
const client = new libreverse.LibreverseService(
    "localhost:50051",
    grpc.credentials.createInsecure(),
);

// Make request
client.getAllExperiences({}, (error, response) => {
    if (error) {
        console.error("Error:", error);
    } else {
        console.log("Experiences:", response.experiences);
    }
});
```

## Running the gRPC Server

### Standalone gRPC Server

```bash
# Start the gRPC server (runs on port 50051 by default)
bundle exec rake grpc:server

# Or specify a different port
GRPC_PORT=9090 bundle exec rake grpc:server
```

### HTTP-based gRPC (via Rails)

The HTTP-based gRPC endpoint is available automatically when the Rails application is running at `/api/grpc`.

## Development and Testing

### Generating gRPC Code

After modifying the `.proto` file, regenerate the gRPC code:

```bash
bundle exec rake grpc:generate
```

### Testing

Both native gRPC and HTTP-based gRPC can be tested using the provided client examples:

```bash
# Test with the Ruby client example
ruby documentation/grpc_client_example.rb
```

## Performance Considerations

- **Native gRPC**: Uses HTTP/2, binary serialization (protobuf), and connection multiplexing for optimal performance
- **HTTP-based gRPC**: Easier to integrate but less efficient due to JSON serialization and HTTP/1.1 overhead
- **Authentication**: Session-based auth adds minimal overhead; consider token-based auth for high-performance scenarios

## Migration from XML-RPC

The gRPC API provides the same functionality as the XML-RPC API with these advantages:

1. **Type Safety**: Protobuf definitions ensure type safety
2. **Performance**: Binary serialization and HTTP/2 improve performance
3. **Code Generation**: Automatic client/server code generation
4. **Streaming**: Support for streaming requests/responses (can be added later)
5. **Multi-language Support**: Official gRPC support for many languages

Method mapping from XML-RPC to gRPC:

| XML-RPC Method                 | gRPC Method              |
| ------------------------------ | ------------------------ |
| `experiences.all`              | `GetAllExperiences`      |
| `experiences.get`              | `GetExperience`          |
| `experiences.create`           | `CreateExperience`       |
| `experiences.update`           | `UpdateExperience`       |
| `experiences.delete`           | `DeleteExperience`       |
| `experiences.approve`          | `ApproveExperience`      |
| `experiences.pending_approval` | `GetPendingExperiences`  |
| `preferences.get`              | `GetPreference`          |
| `preferences.set`              | `SetPreference`          |
| `preferences.dismiss`          | `DismissPreference`      |
| `admin.experiences.approve`    | `AdminApproveExperience` |
