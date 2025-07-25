# Enhanced Caching Implementation

This file documents the caching optimizations implemented in the Libreverse application.

## Changes Made

### 1. Enhanced Caching Concern (`app/controllers/concerns/enhanced_caching.rb`)

Created a reusable concern with the following features:

- **Weak ETags**: More efficient `W/"etag"` format for better browser handling
- **Combined ETag + Last-Modified**: Dual conditional request handling
- **Enhanced Cache-Control headers**: Including `must-revalidate` and `stale-while-revalidate`
- **Automatic Vary headers**: Based on request characteristics
- **Cache invalidation helpers**: For programmatic cache busting

### 2. Controller Enhancements

Updated controllers to use enhanced caching:

#### DashboardController

- Uses combined ETag and Last-Modified headers
- 10-minute cache with `must-revalidate`
- Private caching with proper Vary headers

#### SearchController

- Enhanced ETag with user role and query fingerprint
- 2-minute cache with 30-second `stale-while-revalidate`
- Better user experience during cache updates

#### RobotsController & WellKnownController

- Public caching with `must-revalidate`
- Last-Modified headers based on instance settings
- 1-day cache duration with proper revalidation

### 3. Application Helper Enhancements (`app/helpers/application_helper.rb`)

Added fragment caching helpers:

- `cache_fragment()`: Smart fragment caching with dependency tracking
- `cache_collection()`: Efficient collection rendering with per-item caching
- `cache_if()`: Conditional caching based on runtime conditions
- `generate_enhanced_cache_key()`: Automatic cache key generation
- `invalidate_fragment_cache()`: Programmatic cache invalidation

## Usage Examples

### Fragment Caching in Views

```haml
-# Cache expensive partial rendering
= cache_fragment("experience_details", @experience, current_account, expires_in: 1.hour) do
  .experience-card
    %h3= @experience.title
    %p= @experience.description
    .metadata
      %span.author= @experience.author
      %span.date= @experience.created_at.strftime("%B %d, %Y")

-# Cache collection rendering
= cache_collection(@experiences, "experience_list_item", expires_in: 30.minutes) do |experience|
  .experience-summary
    %h4= link_to experience.title, experience_path(experience)
    %p= truncate(experience.description, length: 100)

-# Conditional caching (only for expensive operations)
= cache_if(@experiences.count > 10, "large_experience_list", @experiences.maximum(:updated_at)) do
  = render "experiences/large_list", experiences: @experiences
```

### Controller Caching

```ruby
class ExperiencesController < ApplicationController
  include EnhancedCaching

  def show
    @experience = Experience.find(params[:id])

    # Enhanced caching with ETag and Last-Modified
    return if fresh_when_enhanced(
      etag_content: @experience.id,
      last_modified: @experience.updated_at,
      public: @experience.public?,
      weak_etag: true
    )

    # Set cache headers
    set_cache_headers(
      duration: @experience.public? ? 1.hour : 10.minutes,
      public: @experience.public?,
      must_revalidate: true,
      stale_while_revalidate: @experience.public? ? 2.minutes : nil
    )
  end

  def update
    @experience = Experience.find(params[:id])

    if @experience.update(experience_params)
      # Invalidate related caches
      invalidate_cache_for(@experience, additional_keys: [
        "experience_list",
        "user_experiences/#{@experience.user_id}"
      ])

      redirect_to @experience
    else
      render :edit
    end
  end
end
```

## Static Asset Caching Configuration

### Nginx Configuration (Recommended)

Add to your Nginx configuration:

```nginx
# Static assets with long-term caching
location ~* \.(css|js|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/css application/javascript font/woff font/woff2;
}

# Images with medium-term caching
location ~* \.(png|jpg|jpeg|gif|ico|svg|webp|avif)$ {
    expires 30d;
    add_header Cache-Control "public, must-revalidate";
    add_header Vary "Accept-Encoding";
}

# Application pages (handled by Rails)
location / {
    # Rails handles caching headers
    proxy_pass http://rails_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Respect Rails cache headers
    proxy_cache_bypass $http_cache_control;
}
```

## Performance Benefits

1. **Reduced Server Load**: Fragment caching reduces expensive operations
2. **Better User Experience**: `stale-while-revalidate` serves cached content while updating
3. **Efficient Bandwidth Usage**: Proper ETag implementation reduces unnecessary transfers
4. **Smart Invalidation**: Automatic cache key generation includes dependencies
5. **Development Friendly**: Caching disabled in development to avoid masking errors

## Cache Invalidation Strategy

The system includes several cache invalidation mechanisms:

1. **Time-based**: Automatic expiration using `expires_in`
2. **Dependency-based**: Cache keys include model timestamps
3. **Manual**: `invalidate_cache_for()` helper for explicit invalidation
4. **Conditional**: ETags and Last-Modified for efficient conditional requests

## Monitoring and Debugging

To monitor cache performance:

```ruby
# In Rails console
Rails.cache.stats  # View cache statistics
Rails.cache.clear  # Clear all caches (development only)

# Check specific cache entries
Rails.cache.exist?("your_cache_key")
Rails.cache.read("your_cache_key")
```

## Next Steps

1. **Monitor cache hit rates** in production
2. **Add cache warming** for critical pages
3. **Implement cache preloading** for common queries
4. **Consider Redis** for distributed caching if scaling horizontally
5. **Add cache metrics** to application monitoring
