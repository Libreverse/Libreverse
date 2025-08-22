# GDPR-Compliant Error Tracking Setup Guide

## Quick Setup

1. **GlitchTip DSN configured:**
    - The GlitchTip DSN is already hardcoded in the configuration
    - Using: `https://dff68bb3ecd94f9faa29a454704040e8@app.glitchtip.com/12078`
    - No additional environment variables needed for basic setup

2. **Optional environment variables:**

    ```bash
    # Copy the example file (optional)
    cp .env.example .env

    # Optionally set app version for better error tracking
    APP_REVISION=v1.0.0
    ```

3. **For production deployment:**
    - Ensure `RAILS_ENV=production` for backend error tracking to activate
    - Ensure `NODE_ENV=production` for frontend error tracking to activate
    - No DSN configuration needed (already hardcoded)

## Testing

To test that error tracking is working:

1. **Backend test:**

    ```ruby
    # In Rails console (production/staging only)
    Sentry.capture_message("Test backend error tracking")
    ```

2. **Frontend test:**

    ```javascript
    // In browser console (production only)
    Sentry.captureMessage("Test frontend error tracking");
    ```

## GDPR Compliance Features ✅

- ✅ **No IP addresses** collected
- ✅ **No cookies or headers** sent
- ✅ **No user data** transmitted
- ✅ **File paths anonymized** (only filenames kept)
- ✅ **Limited breadcrumbs** (3 backend, 5 frontend max)
- ✅ **No performance monitoring**
- ✅ **90-day automatic deletion** (configure in Sentry)
- ✅ **Production-only** error collection

## What Gets Collected

**✅ Safe to collect:**

- Error messages and stack traces (anonymized)
- Browser/OS information
- Timestamp of errors
- URL where error occurred (without query parameters)

**❌ Never collected:**

- Personal information
- User credentials
- Form data
- Local variables
- Request headers
- Cookies
- IP addresses

## Maintenance

- Review error data quarterly
- Monitor Sentry data retention settings
- Update DSNs if rotating keys
- Check configuration after Sentry SDK updates

## Support

For issues with this implementation, check:

1. Environment variables are set correctly
2. Sentry project is active
3. Application is in production/staging mode
4. Network connectivity to Sentry

The configuration prioritizes GDPR compliance over detailed debugging information.
