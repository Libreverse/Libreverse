=begin

# Rails Initializer for Memory Locking in Phusion Passenger Environments
#
# This initializer secures sensitive data in memory by preventing it from being swapped to disk,
# using the mlockall system call via FFI. It's designed specifically for Phusion Passenger deployments,
# where it runs post-fork in each worker process to ensure per-instance memory locking.
#
# Key Features:
# - Conditional execution: Only activates in production environment, when LOCK_MEMORY=true is set,
#   and when PhusionPassenger is defined (to avoid issues in development or standalone Rails server).
# - Privilege handling: Checks for root UID or allows fallback via ALLOW_NONROOT_MLOCK=true if Ruby
#   binary has CAP_IPC_LOCK capability set (recommended via setcap for security).
# - Logging: Provides info/warn messages for debugging mlockall success or failure.
# - Compatibility: Tailored for Passenger's process management; skips in non-Passenger setups.
#
# Setup Requirements:
# - Set LOCK_MEMORY=true in environment variables.
# - Grant CAP_IPC_LOCK to Ruby binary using setcap (e.g., sudo setcap cap_ipc_lock=+ep /path/to/ruby).
# - Restart Passenger (e.g., touch tmp/restart.txt) and verify with /proc/<pid>/status VmLck.
#
# Additional Considerations:
# - Disable response buffering in your Rack/Rails app to prevent memory issues with locked pages.
#   This can be done by setting Rack::Response buffering to false or using appropriate middleware,
#   as previously discussed, to ensure data isn't buffered in a way that conflicts with memory locking.
#
# Security Note: Avoid running Passenger master as root; use setcap for minimal privilege escalation.
AhAh, Phusion Passenger—classic choice for Rails deploys, especially with Nginx or Apache. It handles process management (forking workers on demand) smoothly, which plays nice with the mlockall setup I sketched earlier. The FFI call to lock memory will execute in each worker process's initializer (post-fork), so it'll apply per-instance without issues. Just a couple tweaks for Passenger compatibility: ensure it's conditional (e.g., only in production), and handle privileges since Passenger runs as your app user (not root).

### Updated Initializer for Passenger
Drop this into `config/initializers/memory_lock.rb`. It checks for Passenger explicitly to avoid dev-mode weirdness and logs for debugging.

```ruby
require 'ffi'

module MemoryLock
 extend FFI::Library
 ffi_lib 'c'

 # Constants from sys/mman.h
 MCL_CURRENT = 1
 MCL_FUTURE = 2

 attach_function :mlockall, [:int], :int
 attach_function :getuid, [], :int # For root check
end

# Only lock in production, under Passenger, and with env flag
if Rails.env.production? && ENV['LOCK_MEMORY'] == 'true' && defined?(PhusionPassenger)
 uid = MemoryLock.getuid
 if uid == 0 || ENV['ALLOW_NONROOT_MLOCK'] == 'true' # Fallback if setcap'd
 flags = MemoryLock::MCL_CURRENT | MemoryLock::MCL_FUTURE
 result = MemoryLock.mlockall(flags)
 if result.zero?
 Rails.logger.info "Memory locked (mlockall) in Passenger worker #{Process.pid}"
 else
 Rails.logger.warn "mlockall failed in Passenger worker #{Process.pid}: #{result} (check privileges)"
 end
 else
 Rails.logger.warn "Skipping mlockall: non-root (uid=#{uid}) and no setcap fallback"
 end
end
```

- **Why Passenger-Specific?** `defined?(PhusionPassenger)` ensures it only runs when Passenger loads the app (via its Rack handler). In standalone `rails s`, it skips.
- **Testing**: Set `LOCK_MEMORY=true` in your env, restart Passenger (`touch tmp/restart.txt`), and tail logs. Check `cat /proc/<pid>/status | grep VmLck` for locked pages >0.

### Privilege Setup (The Key Bit for Passenger)
Passenger spawns Ruby processes as your deploy user (e.g., `www-data`), which lacks `CAP_IPC_LOCK` by default. Options:

1. **Recommended: Use setcap on Ruby Binary**
 - Find your Ruby path: `which ruby` or `passenger-config about ruby`.
 - Run: `sudo setcap cap_ipc_lock=+ep /path/to/your/ruby` (e.g., `/usr/bin/ruby` or RVM's).
 - This grants mlockall perms to any process run by that Ruby, including Passenger workers. No root needed.
 - Verify: `getcap /path/to/ruby` should show `= cap_ipc_lock+ep`.
 - Caveat: If using RVM/Bundler wrappers, apply to the Passenger-spawned executable: `passenger-config --ruby-command` gives the full path.

2. **Alt: Run Passenger Master as Root (Less Secure)**
 - In Nginx config: `passenger_user root;` but this exposes more attack surface—avoid if possible.

3. **Containerized?** If Docker/K8s, add `--cap-add=IPC_LOCK` to your run/compose, or bake setcap into the image.

### Potential Gotchas in Passenger
- **Memory Limits**: mlockall pins *all* current/future pages, so tune Passenger's `passenger_max_pool_size` and `passenger_memory_limit` low to avoid OOM kills (e.g., 512MB per worker if your app's lean).
- **Restart Behavior**: On restarts (e.g., via `touch tmp/restart.txt`), locks reapply per new worker—seamless.
- **Overhead**: Negligible (<1% CPU), but monitor with New Relic or Passenger's stats (`passenger-status`).
- **If It Fails**: Common errno 1 (EPERM) means privilege issue—double-check setcap. For huge heaps, use `mlock` selectively on sensitive buffers instead.

This should slot right in without disrupting your Passenger flow. If you're on Passenger 6+ (check `passenger --version`), it's even smoother with better threading. Share your Nginx/Apache config snippet or Ruby version if you hit errors—I can refine. What's next on the setup?
=end
