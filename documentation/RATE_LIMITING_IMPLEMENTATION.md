# Rate Limiting Implementation

## Overview

The BaseIndexer now includes comprehensive rate limiting support that respects HTTP status codes, `Retry-After` headers, and various rate limit response formats commonly used by APIs.

## Features

### 🚦 **HTTP Response Code Handling**

- **429 Too Many Requests**: Properly parsed and handled
- **503 Service Unavailable**: Treated as temporary rate limiting

### 📅 **Retry-After Header Support**

- **Seconds format**: `Retry-After: 60` (wait 60 seconds)
- **HTTP date format**: `Retry-After: Wed, 03 Aug 2025 01:30:00 GMT`
- **X-RateLimit-Reset**: Unix timestamp or seconds from now

### 🏠 **Domain-Specific Rate Limiting**

- Each domain tracked separately in Rails cache
- Automatic cleanup of expired rate limits
- Prevents unnecessary requests to rate-limited domains

### ⚡ **Smart Fallback Logic**

- If no explicit retry time provided, uses intelligent defaults:
    - `429`: 60 seconds
    - `503`: 30 seconds
    - Other: 10 seconds

## Implementation Details

### Error Classes

```ruby
class RateLimitError < StandardError; end
```

### Key Methods

#### `handle_rate_limit_response(response, url)`

- Extracts retry-after information from response headers
- Stores domain rate limit state in cache
- Raises `RateLimitError` with retry information

#### `extract_retry_after(response)`

- Parses multiple header formats:
    - `Retry-After` (seconds or HTTP date)
    - `X-RateLimit-Reset` (Unix timestamp or seconds)
- Intelligent fallback based on response code

#### `set_domain_rate_limit(domain, retry_after_seconds)`

- Stores rate limit state in Rails cache
- Sets expiration to prevent stale data

#### `domain_rate_limited?(domain)`

- Checks if domain is currently rate limited
- Auto-cleans expired rate limits

#### `wait_for_domain_rate_limit(domain)`

- Blocks execution until rate limit expires
- Used before making requests to rate-limited domains

## Integration

### Request Methods Enhanced

All request methods now check for domain rate limits:

- `make_request(url, options = {})`
- `make_json_request(url, options = {})`
- `make_post_request(url, body, options = {})`

### Retry Logic Integration

- Rate limit errors are thrown and can be caught by existing retry mechanisms
- Errors include `retry_after` accessor for intelligent retry timing
- Domain state is preserved across indexing runs

## Usage Examples

### Automatic Handling

```ruby
# Rate limiting is handled automatically
indexer = Metaverse::DecentralandIndexer.new
response = indexer.make_json_request("https://api.example.com/data")
# If rate limited, will throw RateLimitError with retry information
```

### Manual Error Handling

```ruby
begin
  response = indexer.make_json_request(url)
rescue RateLimitError => e
  puts "Rate limited! Retry after #{e.retry_after} seconds"
  # Domain is automatically marked as rate limited
end
```

### Checking Domain Status

```ruby
if indexer.send(:domain_rate_limited?, "api.example.com")
  puts "Domain is currently rate limited"
else
  # Safe to make requests
end
```

## Benefits

### 🤝 **Respectful Behavior**

- Honors server-specified retry times
- Prevents request spam to overwhelmed APIs
- Maintains good relationships with API providers

### ⚡ **Efficient Operation**

- Avoids unnecessary requests to rate-limited domains
- Reduces failed request overhead
- Improves overall indexing success rates

### 🔄 **Robust Error Handling**

- Graceful degradation during rate limiting
- Detailed logging for monitoring and debugging
- Seamless integration with existing retry logic

## Configuration

Rate limiting behavior can be customized through:

- **Domain-specific cache expiration**: Automatic cleanup
- **Fallback retry times**: Configurable per response code
- **Retry logic integration**: Works with existing `with_retry` patterns

## Monitoring

The system provides comprehensive logging:

- Rate limit detection: `WARN` level
- Retry-after information: `INFO` level
- Domain state changes: `DEBUG` level
- Cache operations: `DEBUG` level

This ensures transparency and enables monitoring of rate limiting behavior across all indexers.
