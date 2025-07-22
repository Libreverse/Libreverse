# Privacy-Focused Analytics Implementation

This document outlines the implementation of Umami analytics in Libreverse with a focus on user privacy and GDPR compliance.

## Analytics Provider: Umami

We use [Umami](https://umami.is/), a privacy-focused, cookieless analytics platform that respects user privacy and complies with GDPR requirements.

## Implementation Details

### Privacy-First Approach

- **Cookieless tracking** - No cookies are stored on user devices
- **Anonymous data collection** - No personal identifiers are collected
- **No cross-site tracking** - Data is not shared with third parties
- **Production-only** - Analytics only run in production environment

### Technical Implementation

#### Self-Hosted Proxy

Instead of loading the analytics script directly from `cloud.umami.is`, we proxy it through our own domain at `/umami/script.js`. This approach provides several benefits:

1. **Enhanced Privacy** - No direct connections to third-party domains
2. **Performance** - Reduces external dependencies and improves loading speed
3. **Ad Blocker Resilience** - Less likely to be blocked by ad blockers
4. **Control** - We maintain control over when and how analytics are loaded

#### Configuration

- **Website ID**: `f46b6f42-9743-4ef0-9e1f-b16833b02897`
- **Service**: Umami Cloud
- **Script URL**: `/umami/script.js` (proxied from `https://cloud.umami.is/script.js`)
- **Environment**: Production only
- **Loading**: Asynchronous and deferred

## Privacy Policy Language

When implementing this analytics system, include the following language in your privacy policy:

### Website Analytics

We collect minimal, anonymous website usage data to understand how our service is being used and to improve user experience.

**Data collected:**

- Page views and basic navigation patterns
- Referrer information (which website brought you here)
- Browser type and operating system information
- Geographic region (country/state level only)
- Device type (desktop, mobile, tablet)

**Data NOT collected:**

- Personal identifiers or account information
- Cookies or tracking pixels
- Individual user behavior across sessions
- Precise location data
- Cross-site tracking data

**Technical implementation:**

- Cookieless tracking system
- Anonymous data collection
- Self-hosted proxy for enhanced privacy
- No data sharing with third parties

**Data retention:** Analytics data is retained according to Umami Cloud's standard retention policy.

**Legal basis:** Legitimate interests in understanding website usage and improving user experience.

**Opt-out:** Users with ad blockers or JavaScript disabled automatically opt out of analytics collection.

## Performance Optimization

### DNS Optimization

We implement DNS prefetch and preconnect directives for the Umami Cloud service to improve loading performance:

```haml
%link{rel: "dns-prefetch", href: "//cloud.umami.is"}
%link{rel: "preconnect", href: "https://cloud.umami.is"}
```

### Caching Strategy

The proxied analytics script is cached for 24 hours to reduce server load and improve performance:

```ruby
'Cache-Control' => 'public, max-age=86400'
```

## Public Transparency

Analytics data can be viewed publicly at: [Umami Dashboard](https://umami.geor.me/share/lDVLILfgKDj92Shd/geor.me) (if configured)

This transparency allows users to see exactly what data is being collected and how their usage contributes to overall website metrics.

## Security Considerations

### Content Security Policy

The implementation includes appropriate security headers:

- `X-Content-Type-Options: nosniff` prevents MIME type sniffing attacks
- Proper Content-Type headers ensure browser security

### Error Handling

The proxy implementation includes robust error handling:

- Network timeouts are handled gracefully
- Failed requests return 404 instead of exposing errors
- Errors are logged for monitoring but don't break page functionality

## Testing

Comprehensive tests ensure the analytics implementation works correctly:

- Production environment detection
- Proxy functionality validation
- Error handling verification
- Security header validation

## Compliance Benefits

This implementation achieves GDPR compliance through:

1. **Data Minimization** - Only essential analytics data is collected
2. **Anonymization** - No personal identifiers are captured
3. **Transparency** - Clear documentation of what data is collected
4. **Control** - Users can easily opt out via ad blockers or JavaScript settings
5. **No Cookies** - Eliminates cookie consent requirements
6. **Self-Hosted Proxy** - Reduces data sharing with third parties

## Maintenance

- Monitor proxy endpoint for availability
- Review analytics data retention policies
- Update documentation as needed
- Test analytics functionality after deployments
