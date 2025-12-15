# Spring Configuration for Libreverse

This Rails application now uses [Spring](https://github.com/rails/spring) preloader for faster development workflow.

## What Spring Does

Spring speeds up development by keeping your application running in the background, so you don't need to boot it every time you run a test, rake task, or migration.

## Benefits

- **Faster command execution**: Rails commands like `bin/rails runner`, `bin/rake`, and `bin/rails console` start much faster
- **Automatic reloading**: Your application code is reloaded on each run
- **Smart restarts**: Application automatically restarts when configs, initializers, or gem dependencies change
- **Zero configuration**: Works automatically once set up

## Usage

All your existing commands work the same way, but faster:

```bash
# These commands now run through Spring automatically:
bin/rails console
bin/rails generate
bin/rails runner
bin/rake <task>

# You'll see "Running via Spring preloader" when Spring is active
```

## Managing Spring

### Check Status

```bash
bin/spring status
```

### Stop Spring

```bash
bin/spring stop
```

### Temporarily Disable Spring

```bash
DISABLE_SPRING=1 bin/rails console
```

## Configuration

Spring configuration is in `config/spring.rb`. Current settings:

- Watches additional config files like `config/bannedwords.yml` and `config/spamwords.yml`
- Configured for optimal performance with this application
- Set to show Spring status messages (can be quieted)

## Troubleshooting

### If commands seem slow

Spring might need to restart. Check status:

```bash
bin/spring status
```

### If you see strange behavior

Restart Spring:

```bash
bin/spring stop
# Next command will start Spring fresh
```

### Debugging

Run Spring in foreground to see what's happening:

```bash
spring server
```

## Environment Compatibility

- ✅ **Ruby 3.4.2**: Fully supported
- ✅ **Rails 8.x**: Fully supported
- ✅ **Development**: Enabled with reloading
- ✅ **Test**: Enabled with reloading for Spring compatibility

## Notes

- Spring is only active in development and test environments
- Production deployments exclude Spring (it's in the development group)
- Uses pnpm for package management as per project standards
- Works seamlessly with the existing development workflow
