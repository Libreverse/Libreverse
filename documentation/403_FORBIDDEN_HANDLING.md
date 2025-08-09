# 403 Forbidden Response Handling

## 🚫 **Intelligent 403 Blocking System**

The BaseIndexer now includes smart handling of 403 Forbidden responses that treats them as temporary blocks with monthly rechecking, ensuring we don't permanently lose indexing capabilities due to accidental or temporary blocks.

## 🎯 **Key Features**

### Temporary Domain Blocking

- **30-Day Blocks**: Domains returning 403 are blocked for 30 days
- **Automatic Recheck**: After 30 days, the block expires and access is retried
- **Graceful Recovery**: Handles accidental blocks and policy changes
- **Persistent Storage**: Uses Rails cache with long expiration times

### Smart Error Classification

- **403 Forbidden**: Monthly recheck for potential recovery
- **429 Too Many Requests**: Short-term rate limiting with Retry-After respect
- **503 Service Unavailable**: Temporary service issues with quick retry
- **4xx Client Errors**: Permanent failures (no retry)
- **5xx Server Errors**: Temporary server issues (immediate retry)

## 🔧 **Implementation Details**

### New Error Class

```ruby
class ForbiddenAccessError < StandardError; end
```

### Core Methods

#### `handle_forbidden_response(response, url)`

- Logs the 403 response with domain information
- Sets a 30-day block on the domain
- Raises `ForbiddenAccessError` with recheck information

#### `set_domain_block(domain, block_duration_seconds)`

- Stores domain block in Rails cache
- Sets expiration to block duration + 1 day buffer
- Logs block information with human-readable dates

#### `domain_blocked?(domain)`

- Checks if domain is currently blocked
- Auto-expires old blocks and logs recheck attempts
- Returns boolean status with debug logging

### Request Flow Integration

All request methods now check for domain blocks before making requests:

1. **Pre-request Check**: Verify domain isn't blocked
2. **403 Response**: Handle and block domain for 30 days
3. **Block Expiry**: Automatic cleanup and recheck logging
4. **Request Prevention**: Block future requests during cooling-off period

## 📊 **Monitoring & Logging**

### Block Events

```ruby
[WARN] [PLATFORM] Access forbidden by api.example.com: HTTP 403
[INFO] [PLATFORM] Domain will be blocked for 30 days, then rechecked in case of temporary/accidental block
[INFO] [PLATFORM] Blocked domain api.example.com until 2025-09-02 (30 days)
```

### Block Status

```ruby
[DEBUG] [PLATFORM] Domain api.example.com is blocked for 15 more days (until 2025-09-02)
```

### Recheck Events

```ruby
[INFO] [PLATFORM] Domain block expired for api.example.com - will attempt to recheck access
```

## 🎯 **Benefits**

### Graceful Recovery

- **Temporary Blocks**: Recovers from accidental 403 responses
- **Policy Changes**: Adapts to changing API access policies
- **Human Error**: Handles admin mistakes or configuration issues
- **Service Updates**: Accommodates temporary service restrictions

### Respectful Behavior

- **Cooling-off Period**: Gives domains time to resolve access issues
- **Reduced Load**: Prevents repeated failed requests to blocked domains
- **Clear Attribution**: Logs show why domain was blocked and when it will be rechecked
- **Predictable Behavior**: Consistent 30-day recheck cycle

### Operational Resilience

- **No Permanent Loss**: Never permanently abandons indexing a domain
- **Automatic Recovery**: No manual intervention required for recovery
- **Resource Efficiency**: Prevents wasted requests to blocked domains
- **Debugging Support**: Rich logging for troubleshooting access issues

## ⚙️ **Configuration**

### Block Duration

Currently hard-coded to 30 days, but can be made configurable:

```ruby
# Future enhancement - configurable block duration
block_duration = config.fetch("forbidden_block_days") { 30 }.days.to_i
```

### Cache Settings

- **Storage**: Rails cache with long expiration
- **Buffer Time**: +1 day buffer beyond block duration
- **Cleanup**: Automatic cleanup of expired blocks

## 🧪 **Testing Scenarios**

### Test Cases Covered

- ✅ **Domain Block Setting**: Properly stores 30-day blocks
- ✅ **Block Status Checking**: Correctly identifies blocked domains
- ✅ **Request Prevention**: Blocks requests to forbidden domains
- ✅ **Error Handling**: Proper `ForbiddenAccessError` generation
- ✅ **Block Expiry**: Automatic cleanup and recheck logging
- ✅ **Integration**: Works with all request methods (GET, POST, Capybara)

### Real-World Scenarios

- **API Key Revocation**: Temporary loss of access, restored after 30 days
- **Policy Changes**: New restrictions that may be lifted later
- **Server Misconfiguration**: Admin errors that get fixed over time
- **Service Maintenance**: Temporary access restrictions during updates

## 🔄 **Recovery Process**

### Automatic Recovery Flow

1. **403 Response**: Domain blocked for 30 days
2. **Block Period**: All requests to domain are prevented
3. **Block Expiry**: Cache entry expires after 30 days
4. **Next Request**: System attempts access again
5. **Success**: Normal operation resumes
6. **Failure**: New 30-day block cycle begins

### No Manual Intervention Required

- **Self-Healing**: System automatically retries after cooling-off period
- **Zero Configuration**: Works out of the box with sensible defaults
- **Transparent Operation**: All actions logged for visibility
- **Resilient Design**: Handles edge cases and error conditions gracefully

This implementation ensures that 403 responses don't permanently block indexing while still being respectful of domains that have explicitly forbidden access. The monthly recheck cycle provides a balance between persistence and respect for domain policies.
