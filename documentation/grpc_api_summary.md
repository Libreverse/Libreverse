# Libreverse gRPC API Documentation

This document describes the gRPC API implementation for Libreverse, providing both native gRPC and HTTP-based access to the API functionality.

## Overview

The Libreverse gRPC API provides a modern, efficient alternative to the existing XML-RPC API. It offers:

- **Type Safety**: Protocol Buffer schema validation
- **Performance**: Binary serialization and HTTP/2 multiplexing
- **Dual Access**: Both native gRPC and HTTP-based JSON endpoints
- **Language Support**: Auto-generated clients for multiple programming languages
- **Backward Compatibility**: Equivalent functionality to XML-RPC API

## Architecture

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   gRPC Client   │────│  gRPC Server     │────│  Rails Models   │
│   (Port 50051)  │    │  (Native)        │    │  (ActiveRecord) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
┌─────────────────┐    ┌──────────────────┐
│  HTTP Client    │────│  gRPC Controller │
│  (Port 3000)    │    │  (JSON Bridge)   │
└─────────────────┘    └──────────────────┘
```

## Endpoints

### Native gRPC Server

- **Host**: localhost (configurable via `GRPC_HOST`)
- **Port**: 50051 (configurable via `GRPC_PORT`)
- **Protocol**: gRPC over HTTP/2
- **Authentication**: Metadata-based session tokens

### HTTP-based gRPC

- **Endpoint**: `POST /api/grpc`
- **Protocol**: JSON over HTTP/1.1
- **Authentication**: Session cookies or headers
- **Content-Type**: `application/json`

## API Methods

All methods implemented with equivalent functionality to XML-RPC API:

- **GetAllExperiences** - List experiences
- **GetExperience** - Get specific experience
- **CreateExperience** - Create new experience (auth required)
- **UpdateExperience** - Update owned experience (auth required)
- **DeleteExperience** - Delete owned experience (auth required)
- **ApproveExperience** - Approve owned experience (auth required)
- **GetPendingExperiences** - List pending experiences (auth required)
- **GetPreference** - Get user preference (auth required)
- **SetPreference** - Set user preference (auth required)
- **DismissPreference** - Dismiss user preference (auth required)
- **AdminApproveExperience** - Approve any experience (admin required)

## Usage Examples

### HTTP-based gRPC (Recommended for web apps)

```bash
# Get all experiences
curl -X POST http://localhost:3000/api/grpc \
    -H "Content-Type: application/json" \
    -d '{"method": "GetAllExperiences", "request": {}}'

# Create experience (with auth)
curl -X POST http://localhost:3000/api/grpc \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: your_session_id" \
    -d '{
    "method": "CreateExperience",
    "request": {
      "title": "New Experience",
      "description": "Description here",
      "author": "Your Name"
    }
  }'
```

### Native gRPC (Recommended for microservices)

```ruby
# Ruby client example
stub = Libreverse::Grpc::LibreverseService::Stub.new('localhost:50051', :this_channel_is_insecure)
request = Libreverse::Grpc::GetAllExperiencesRequest.new
response = stub.get_all_experiences(request)
```

## Development

### Starting Services

```bash
# Start all services (recommended)
foreman start -f Procfile.dev

# Start gRPC server only
bundle exec rake grpc:server
```

### Running Tests

```bash
bundle exec rails test test/controllers/api/grpc_controller_test.rb
```

## Security

- Rate limiting: 30 requests/minute
- Session-based authentication
- Role-based authorization
- SSL support in production

For complete documentation, see `/documentation/grpc_api.md` (to be created) and the client example in `/documentation/grpc_client_example.rb`.
