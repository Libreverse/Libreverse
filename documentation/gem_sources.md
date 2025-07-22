# Gem Source Management

This project includes a helper script to switch between gem sources when needed.

## Usage

```bash
# Check current status
bin/gem-source status

# Switch to official RubyGems (better CDN, recommended)
bin/gem-source rubygems

# Switch to Chinese mirror (when RubyGems is blocked)
bin/gem-source mirror
```

## Why?

- **Primary**: Official RubyGems (`https://rubygems.org`) - Better CDN and always up-to-date
- **Fallback**: Chinese mirror (`https://mirrors.tuna.tsinghua.edu.cn/rubygems`) - For when RubyGems is blocked

The script avoids bundler's security warning about multiple global sources by maintaining a single source at a time.

## Security Note

Thor gem has been explicitly pinned to `>= 1.4.0` to address CVE-2025-54314.
