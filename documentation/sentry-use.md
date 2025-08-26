# GDPR-Compliant Error Tracking Implementation

This document outlines the implementation of error tracking in Libreverse with GDPR compliance through data minimization.

## Privacy Policy Language

When implementing this error tracking system, include the following language in your privacy policy:

### Error Tracking and Monitoring

We collect minimal technical error information to fix website problems and improve user experience.

**Data collected:**

- Error messages and stack traces (with file paths anonymized)
- Browser type and operating system information
- Page URL where the error occurred
- Timestamp of the error

**Data NOT collected:**

- IP addresses
- Cookies or session data
- Request headers
- User account information
- Local variables or form data
- Personal information of any kind

**Data retention:** Error data is automatically deleted after 90 days.

**Legal basis:** Legitimate interests in maintaining website functionality and improving user experience.

**Transparency note:** We have specifically configured our error tracking system to minimize data collection and exclude all personal information while maintaining our ability to debug and fix technical issues.

## Technical Implementation

### Backend Configuration

- Configured in `config/initializers/sentry.rb`
- Removes request headers, cookies, and user context before sending
- Limits breadcrumbs to last 3 only
- Disables performance monitoring
- Only enabled in production/staging environments

### Frontend Configuration

- Configured in `app/javascript/application.js`
- Removes user data and request information
- Anonymizes file paths in stack traces
- Disables automatic breadcrumbs and console capture
- Only enabled in production with valid DSN

### Environment Variables

- `SENTRY_DSN`: Backend Sentry project DSN
- `VITE_SENTRY_DSN`: Frontend Sentry project DSN
- `APP_REVISION`: Optional app version for error tracking

## Compliance Features

1. **Data Minimization**: Only collects essential debugging information
2. **Anonymization**: Removes file paths, personal data, and identifiers
3. **Limited Retention**: 90-day automatic deletion
4. **No PII**: Specifically configured to exclude personally identifiable information
5. **Selective Collection**: Only captures errors, not user behavior or analytics

## Testing

To test the implementation:

1. Set up a Sentry project at sentry.io or self-hosted instance
2. Configure environment variables with your DSN
3. Deploy to staging/production environment
4. Trigger an error to verify data collection is minimal and compliant
5. Check Sentry dashboard to ensure no personal data is captured

## Maintenance

- Review error data quarterly to ensure compliance
- Update configuration if Sentry SDK changes
- Monitor data retention settings
- Audit captured data types periodically
