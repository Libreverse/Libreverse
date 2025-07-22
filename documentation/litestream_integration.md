# Litestream Integration Documentation

This document describes the Litestream database replication integration in LibReverse.

## Overview

Litestream provides real-time SQLite database replication to cloud storage. This integration automatically backs up your SQLite databases to S3-compatible storage and provides an admin dashboard to monitor and manage the replication process.

## Environment Variables

Litestream **requires** specific environment variables to be set for security and durability:

### Required Variables (Production)

In production, the application **will crash on startup** if these variables are missing, ensuring that database durability is never compromised:

- `LITESTREAM_REPLICA_BUCKET` - The S3 bucket name or full S3 URL for backups
- `LITESTREAM_ACCESS_KEY_ID` - S3 access key ID for authentication
- `LITESTREAM_SECRET_ACCESS_KEY` - S3 secret access key for authentication

### Optional Variables

- `LITESTREAM_REPLICA_REGION` - AWS region (defaults to "us-east-1")
- `LITESTREAM_REPLICA_ENDPOINT` - Custom S3 endpoint for non-AWS providers

### Development vs Production

- **Development**: Missing environment variables result in warnings and Litestream is disabled
- **Production**: Missing environment variables cause the application to crash with a fatal error, preventing deployments without proper backup configuration

## Production Setup

1. **Set Environment Variables**: Configure the required environment variables in your production environment.

2. **Automatic Startup**: The Litestream process starts automatically when the Rails application boots via the `config/initializers/litestream_in_process.rb` initializer.

3. **Process Management**: Similar to Solid Queue, Litestream runs as a separate forked process that's managed by the main Rails application.

## Development Setup

1. **Add to Procfile.dev**: Litestream is automatically added to the development Procfile to run alongside other services.

2. **Local Testing with MinIO**: You can test Litestream locally using a Docker MinIO instance:

    ```bash
    docker run -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address ":9001"
    ```

    Then set these environment variables:

    ```bash
    export LITESTREAM_REPLICA_BUCKET="s3://mybkt.localhost:9000/"
    export LITESTREAM_ACCESS_KEY_ID="minioadmin"
    export LITESTREAM_SECRET_ACCESS_KEY="minioadmin"
    export LITESTREAM_REPLICA_ENDPOINT="http://localhost:9000"
    ```

## Admin Dashboard

The Litestream admin interface is available at `/admin/litestream` and provides:

### Status Overview

- Configuration status (environment variables check)
- Process status (whether Litestream is running)
- Database count

### Database Management

- List all configured databases
- View generations for each database
- View snapshots for each database
- Verify database backups

### Built-in Dashboard

- Access to the full Litestream web dashboard at `/admin/litestream/dashboard`
- Secured with admin authentication

## Configuration Files

### Litestream Configuration (`config/litestream.yml`)

Defines which databases to replicate and where to store backups. The configuration uses environment variables for security.

### Initializer (`config/initializers/litestream.rb`)

Configures the Litestream gem with:

- Environment variable validation
- Dashboard authentication
- Admin controller integration

### Process Manager (`config/initializers/litestream_in_process.rb`)

Manages the Litestream process lifecycle:

- Automatic startup with the Rails application
- Process monitoring and cleanup
- Environment variable validation

## Security Features

### Environment Variable Requirements

Unlike other LibReverse features, Litestream **requires** environment variables to be set. This ensures:

- Secrets are not stored in the codebase
- Production deployments are explicitly configured
- Development environments can opt-in to replication

### Admin Authentication

- Dashboard access requires admin privileges
- Uses the existing LibReverse admin authentication system
- Additional HTTP basic auth can be configured for production

### Process Isolation

- Litestream runs as a separate process to avoid blocking the main application
- Automatic cleanup on application shutdown
- Process monitoring to detect failures

## Monitoring and Operations

### Status Checking

The admin dashboard shows:

- Whether required environment variables are set
- Whether the Litestream process is running
- Number of configured databases

### Backup Verification

You can verify backups through:

- Admin dashboard "Verify Backup" button
- Direct API calls to `/admin/litestream/verify`
- Programmatic verification using `Litestream.verify!`

### Restoration

Database restoration can be performed via:

- Rails rake task: `rails litestream:restore -- --database=path/to/db.sqlite3`
- Programmatic restoration using `Litestream::Commands.restore`

## Integration with LibReverse

### Process Management

Litestream follows the same pattern as Solid Queue:

- Automatic startup via initializer
- Forked process management
- Development Procfile integration
- No manual process management required in production

### Admin System Integration

- Secured with existing admin authentication
- Consistent UI styling with other admin pages
- Navigation integration in admin layout

### Environment Variable Handling

Unlike other LibReverse components that use database settings with environment variable fallbacks, Litestream requires explicit environment variables for security compliance.

**Critical Production Requirement**: The application will crash on startup in production if required Litestream environment variables are missing. This ensures database durability is never compromised due to misconfiguration.

## Troubleshooting

### Litestream Not Starting

1. Check environment variables are set
2. Verify S3 credentials and bucket access
3. Check Rails logs for error messages
4. Ensure no other Litestream processes are running

### Backup Verification Failures

1. Check replication lag - allow time for backups to sync
2. Verify S3 connectivity and permissions
3. Check Litestream configuration file syntax
4. Monitor Litestream process logs

### Dashboard Access Issues

1. Ensure user has admin privileges
2. Check admin authentication configuration
3. Verify routes are properly mounted

## Related Files

- `app/controllers/admin/litestream_controller.rb` - Admin dashboard controller
- `app/views/admin/litestream/index.haml` - Admin dashboard view
- `app/javascript/controllers/admin_litestream_controller.coffee` - Frontend interactions
- `config/initializers/litestream.rb` - Litestream gem configuration
- `config/initializers/litestream_in_process.rb` - Process management
- `config/litestream.yml` - Litestream configuration file
- `config/routes.rb` - Admin routes for Litestream
- `Procfile.dev` - Development process definitions
