# gRPC Server Integration

The Libreverse application includes a gRPC server that is integrated directly into the main Rails application process.

## How It Works

The gRPC server starts automatically when the Rails application starts, running in a background thread within the same process. This provides:

- **Simplified deployment**: No need to manage separate processes
- **Shared resources**: Direct access to Rails models and services
- **Better performance**: No inter-process communication overhead

## Development

In development, the gRPC server starts automatically with the Rails application:

```bash
# Start all services (web server includes gRPC)
bin/dev
```

The gRPC server will start on port 50051 by default alongside the web server.

## Configuration

The gRPC server is configured in `config/initializers/grpc.rb`:

- **Port**: `GRPC_PORT` environment variable (default: 50051)
- **Host**: `GRPC_HOST` environment variable (default: 0.0.0.0)
- **SSL**: Enabled in production with `GRPC_SSL_CERT_PATH` and `GRPC_SSL_KEY_PATH`
- **Rate limiting**: 30 requests per minute per IP
- **Authentication**: Session-based via cookies or headers

## API Access

The gRPC server can be accessed in two ways:

### 1. Native gRPC

Connect directly to the gRPC server on port 50051 using any gRPC client:

```ruby
# Ruby example
require 'grpc'
stub = Libreverse::Grpc::LibreverseService::Stub.new('localhost:50051', :this_channel_is_insecure)
response = stub.get_all_experiences(Libreverse::Grpc::GetAllExperiencesRequest.new)
```

### 2. HTTP Bridge

Use the HTTP bridge at `/api/grpc` for easier web client access:

```javascript
// JavaScript example
const response = await fetch("/api/grpc", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
        method: "GetAllExperiences",
        request: {},
    }),
});
```

## Available Methods

- **GetAllExperiences**: Get all experiences (filtered by permissions)
- **GetExperience**: Get a specific experience by ID
- **CreateExperience**: Create a new experience (authenticated)
- **UpdateExperience**: Update an experience (authenticated, owner only)
- **DeleteExperience**: Delete an experience (authenticated, owner only)
- **ApproveExperience**: Approve an experience (admin only)
- **GetPendingExperiences**: Get pending approval experiences (admin only)
- **GetPreference**: Get user preference (authenticated)
- **SetPreference**: Set user preference (authenticated)
- **DismissPreference**: Dismiss user preference (authenticated)

## Authentication

gRPC requests are authenticated using:

1. **Session cookies** (for web clients)
2. **Session-ID header** (`X-Session-ID`)
3. **Authorization header** (for bearer tokens, if implemented)

## Error Handling

The gRPC server returns standard gRPC status codes:

- `UNAUTHENTICATED`: Authentication required
- `PERMISSION_DENIED`: Insufficient permissions
- `INVALID_ARGUMENT`: Invalid request parameters
- `NOT_FOUND`: Resource not found
- `INTERNAL`: Server error

These are mapped to appropriate HTTP status codes when using the HTTP bridge.
