# Advanced Iodine Build Configuration

This file contains optional compile-time optimizations for iodine. These require rebuilding the gem.

## To apply these optimizations:

```bash
# Uninstall current iodine
gem uninstall iodine

# Reinstall with custom compile flags
gem install iodine -- \
    --with-cflags="-DHTTP_MAX_HEADER_LENGTH=16384 -DHTTP_MAX_HEADER_COUNT=64 -DFIO_USE_RISKY_HASH=1 -DHTTP_BUSY_UNLESS_HAS_FDS=64"
```

## Optimization Flags Explained:

- `HTTP_MAX_HEADER_LENGTH=16384`: Increases header size limit to 16KB (default: 8KB)
  Good for applications with large headers (authentication tokens, etc.)

- `HTTP_MAX_HEADER_COUNT=64`: Reduces header count limit to 64 (default: 128)
  Saves memory per connection, good for high-concurrency apps

- `FIO_USE_RISKY_HASH=1`: Uses RiskyHash instead of SipHash
  Faster hashing for internal operations (safe due to iodine's collision protection)

- `HTTP_BUSY_UNLESS_HAS_FDS=64`: Requires 64 free file descriptors before accepting new connections
  Prevents resource exhaustion under high load

## Production Optimizations:

For production servers with high memory and many connections:

```bash
gem install iodine -- \
    --with-cflags="-DFIO_MAX_SOCK_CAPACITY=262144 -DFIO_USE_RISKY_HASH=1 -DHTTP_BUSY_UNLESS_HAS_FDS=128"
```

- `FIO_MAX_SOCK_CAPACITY=262144`: Increases max client capacity to 256K (default: 128K)

## Memory-Constrained Environments:

For containers or memory-limited environments:

```bash
gem install iodine -- \
    --with-cflags="-DFIO_MAX_SOCK_CAPACITY=32768 -DHTTP_MAX_HEADER_COUNT=32 -DHTTP_MAX_HEADER_LENGTH=4096"
```

## Development Debugging:

For debugging memory issues:

```bash
gem install iodine -- \
    --with-cflags="-DFIO_FORCE_MALLOC=1 -DFIO_LOG_LENGTH_LIMIT=4096"
```

- `FIO_FORCE_MALLOC=1`: Uses system malloc instead of custom allocator
- `FIO_LOG_LENGTH_LIMIT=4096`: Increases log message length limit

## Note:

These optimizations are optional. The default build is well-optimized for most use cases.
Only apply these if you have specific performance requirements or constraints.
