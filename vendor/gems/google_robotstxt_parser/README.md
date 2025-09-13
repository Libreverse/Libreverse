# google_robotstxt_parser (vendored)

This tree vendors a tiny Ruby C-extension wrapper around Google's `robotstxt` C++ library, built from submodules:

- ext/robotstxt/robotstxt/ -> google/robotstxt submodule
- ext/robotstxt/abseil-cpp -> abseil/abseil submodule (pinned)

## Build notes

- The extension generates a minimal CMake project and links to the local submodules only (no network).
- Requires cmake and a C++17 compiler.

## Usage

```ruby
require "google_robotstxt_parser"
allowed = Robotstxt.allowed_by_robots(robots_txt_string, "MyBot", "https://example.com/")
```

Do not commit build artifacts under `ext/robotstxt/c-build`. Submodule pointers are pinned for reproducible builds.

This tree vendors a tiny Ruby C-extension wrapper around Google's `robotstxt` C++ library, built from submodules:

- ext/robotstxt/robotstxt/ -> google/robotstxt submodule
- ext/robotstxt/abseil-cpp -> abseil/abseil submodule (pinned)

Build notes
- The extension generates a minimal CMake project and links to the local submodules only (no network).
- Requires cmake and a C++17 compiler.

Usage
  require "google_robotstxt_parser"
  allowed = Robotstxt.allowed_by_robots(robots_txt_string, "MyBot", "https://example.com/")

Do not commit build artifacts under ext/robotstxt/c-build. Submodule pointers are pinned for reproducible builds.
# Vendored google_robotstxt_parser

This vendored gem builds against the Google `robotstxt` C++ library from a git submodule placed at:

- vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt

Setup:

- Initialize submodules:
  - git submodule update --init --recursive vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt
- Ensure build tools available:
  - macOS: brew install cmake ninja
  - Debian/Ubuntu (and Docker): apt-get update && apt-get install -y build-essential cmake git

Bundling:

- bundle install will compile the native extension by generating and building the CMake project under robotstxt/c-build.
