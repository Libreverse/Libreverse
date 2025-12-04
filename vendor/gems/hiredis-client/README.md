# HiredisClient (Vendored with TruffleRuby Support)

`hiredis-client` provides a `hiredis` binding for the native `hiredis` client library.

See [`redis-client`](https://github.com/redis-rb/redis-client) for details.

## Libreverse Modifications

This is a vendored copy of hiredis-client v0.26.1 with the following modifications:

1. **TruffleRuby C Extension Support**: The upstream gem's `extconf.rb` only compiles
   the native C extension for CRuby (`RUBY_ENGINE == "ruby"`). TruffleRuby now has
   excellent C extension support, so we've patched `extconf.rb` to also compile for
   TruffleRuby (`RUBY_ENGINE == "truffleruby"`).

2. **Auto-compile on first load**: For vendored path gems, Bundler doesn't automatically
   compile native extensions. This version automatically compiles the extension on first
   `require 'hiredis-client'` if it's not already built (similar to google_robotstxt_parser).

### Usage

Just add to your Gemfile:

```ruby
gem "hiredis-client", path: "vendor/gems/hiredis-client"
```

The extension will compile automatically the first time it's loaded. No manual steps needed.
