# User Authentication & Account Management

## Overview

Libreverse uses the secure Rodauth framework for all authentication and account management functionality. This provides a robust, secure system for user registration, login, and account management.

## Authentication Features

### Account Creation

- **Registration Process**: New users can create an account with a valid email address and password
- **Password Requirements**: System enforces strong password requirements:
    - Minimum length of 8 characters
    - Mix of uppercase and lowercase letters
    - At least one number and one special character
    - Rejection of common passwords
- **Email Verification**: Account activation requires email verification
- **CAPTCHA Protection**: Registration form is protected by CAPTCHA to prevent automated submissions

### Login & Session Management

- **Secure Login**: Email and password authentication with rate limiting
- **Multi-phase Authentication** (optional): Two-factor authentication for enhanced security
- **Remember Me**: Optional persistent session for trusted devices
- **Session Timeout**: Automatic session expiration after period of inactivity
- **Concurrent Sessions**: Management of multiple active sessions

### Account Management

- **Profile Editing**: Users can update their profile information
- **Password Change**: Self-service password change functionality
- **Account Recovery**: Secure account recovery flow via email
- **Account Closure**: Self-service account deactivation and deletion options

### Security Features

- **Password Encryption**: Industry-standard bcrypt password hashing
- **Brute Force Protection**: Exponential backoff for failed login attempts
- **Session Fixation Protection**: Session rotation on authentication
- **CSRF Protection**: Cross-site request forgery protections
- **Security Event Logging**: Tracking of all authentication events

## User Flow

1. **Registration**:
    - User navigates to registration page
    - Completes form with email and password
    - Receives verification email
    - Clicks link to verify email
    - Account becomes active

2. **Login**:
    - User enters email and password
    - If multi-factor is enabled, completes second authentication step
    - System establishes authenticated session
    - User is redirected to dashboard or requested page

3. **Password Recovery**:
    - User initiates recovery process
    - System emails recovery link
    - User creates new password
    - Session is established with new credentials

## Integration Points

The authentication system integrates with other Libreverse components:

- **Dashboard**: Personalized experiences based on account
- **Experience Creation**: Association of created content with user account
- **Preferences**: User-specific preferences and settings
- **API Access**: Authentication for XML-RPC API endpoints

## Implementation Details

Libreverse leverages [Rodauth Rails](https://github.com/janko/rodauth-rails), which provides:

- MVC architecture integration
- Database-backed persistence of account data
- Integration with Rails security mechanisms
- Extensible and flexible authentication workflows

The `RodauthController` and associated models handle the core authentication logic, with middleware integration for session management.

## Privacy & Data Protection

- User passwords are never stored in plaintext
- Personal information is stored only as necessary for core functions
- Account deletion permanently removes personal data
- Authentication data is not shared with third parties
