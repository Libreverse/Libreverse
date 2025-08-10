# Instance Blog Deployment Guide

This guide explains how to set up and deploy the instance blog feature using ComfortableMediaSurfer.

**Important**: This is for the **instance blog** (FOSS component), not the official Libreverse blog which is part of the proprietary component.

## Prerequisites

1. Rails application with `comfortable_media_surfer` gem installed
2. Database migrations run (`rails db:migrate`)
3. Assets compiled (`rails comfy:compile_assets`)
4. Admin user account with admin privileges

## Installation Steps

### 1. Initial Setup

```bash
# Install the gem (already in Gemfile)
bundle install

# Run migrations to create CMS tables
bundle exec rails db:migrate

# Compile CMS assets
bundle exec rails comfy:compile_assets
```

### 2. Create Blog Content

Run the blog setup script:

```bash
# One-time setup
bundle exec rails runner db/cms_blog_setup.rb

# Or use the rake task
bundle exec rails cms:setup_blog
```

### 3. Verify Installation

1. **Blog Homepage**: Visit `http://your-domain/blog`
2. **CMS Admin**: Visit `http://your-domain/cms-admin` (requires admin privileges)

## Production Deployment

### Environment Variables

Ensure your instance settings are configured via the admin interface or environment variables:

```bash
# Instance identification (set via InstanceSetting model or ENV)
INSTANCE_DOMAIN=your-instance.com
INSTANCE_NAME="Your Instance Name"
INSTANCE_DESCRIPTION="Your instance description"
```

### Deployment Commands

```bash
# 1. Deploy application
git pull origin main
bundle install

# 2. Run migrations
bundle exec rails db:migrate

# 3. Setup blog (safe to run multiple times)
bundle exec rails cms:setup_blog

# 4. Compile assets
bundle exec rails comfy:compile_assets

# 5. Restart application servers
```

## Available Rake Tasks

```bash
# Setup blog (safe to run multiple times)
rails cms:setup_blog

# Update blog content without destroying structure
rails cms:update_blog

# DESTRUCTIVE: Reset and recreate all blog content
rails cms:reset_blog
```

## Authentication Integration

The blog uses Rodauth integration for admin access:

- **Blog Access**: Public (no authentication required)
- **Admin Access**: Requires admin user account
- **Authentication**: Integrated with existing Rodauth system

## Site Structure

The CMS creates two sites:

1. **Main Site** (`instance-main`): For general CMS content
2. **Blog Site** (`instance-blog`): Dedicated blog content at `/blog` path

## Content Management

### Accessing the Admin

1. Log in as an admin user
2. Visit `/cms-admin`
3. Navigate to the blog site to manage content

### Adding New Posts

1. Go to CMS Admin → Pages
2. Select the blog site
3. Create new page under the blog index
4. Use the "Blog Post" layout
5. Fill in all required fragments (title, content, author, etc.)

## File Structure

```
db/cms_seeds/libreverse-blog/
├── layouts/
│   ├── blog.html              # Main blog layout
│   └── blog_post.html         # Individual post layout
├── pages/
│   └── index/
│       ├── content.html       # Blog homepage
│       ├── welcome-to-libreverse/
│       ├── getting-started/
│       └── privacy-features/
└── snippets/
    └── recent_posts.html      # Recent posts sidebar
```

## Troubleshooting

### "Site Not Found" Error

```bash
# Ensure sites are created
bundle exec rails runner "puts Comfy::Cms::Site.count"

# Re-run setup if needed
bundle exec rails cms:setup_blog
```

### Admin Access Issues

- Verify user has `admin: true` in accounts table
- Check authentication integration in `app/lib/cms_rodauth_authentication.rb`

### Content Not Showing

- Verify pages are published (`is_published: true`)
- Check site hostname matches current domain
- Ensure layouts and fragments are properly created

## Customization

### Styling

Custom styles can be added to:
- `app/assets/stylesheets/comfy/admin/cms/custom.sass` (admin interface)
- Modify layout files in `db/cms_seeds/libreverse-blog/layouts/`

### Adding New Content Types

1. Create new layout in `layouts/`
2. Update seed files
3. Run `rails cms:update_blog`

## Security Notes

- Admin access is restricted to users with `admin: true`
- Public blog content is served without authentication
- CMS admin interface uses secure session management
- All content is sanitized before display

## Monitoring

Check logs for:
- `[ERROR] EmojiReplacer: Error processing request: Site Not Found`
- Authentication failures
- Database connection issues

## Backup

Important data to backup:
- `comfy_cms_*` database tables
- `db/cms_seeds/` directory
- Uploaded files (if using file uploads)
