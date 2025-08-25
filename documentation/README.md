# Libreverse Documentation

Welcome! This folder contains user- and developer-facing docs for Libreverse. The index below organizes everything that remains after pruning non-actionable change logs and status notes.

## 📚 Table of contents

### Getting started and setup

- [Configuration](configuration.md)
- [Spring setup](spring-setup.md)
- [SQLite guide](sqlite-guide.md)
- [Passenger migration guide](passenger-migration-guide.md)
- [Sentry setup](sentry-setup-guide.md)
- [MailHog integration](mailhog-integration.md)
- [Foundation for Emails](foundation-for-emails.md)
- [Gem sources](gem-sources.md)
- [CodeQL quickstart](codeql-quickstart.md)
- [CodeQL security analysis](codeql-security-analysis.md)
- [Litestream integration](litestream-integration.md)

### Core product features

- [Homepage & navigation](homepage-navigation.md)
- [Authentication](authentication.md)
- [Experiences](experiences.md)
- [Search](search.md)
- [Dashboard](dashboard.md)
- [User preferences](user-preferences.md)

### APIs and integrations

- [GraphQL API](graphql-api.md)
- [gRPC API](grpc-api.md)
- [JSON:API](json-api.md)
	- JavaScript client example (inlined at the end)
- [XML-RPC overview](xmlrpc.md)
- [XML-RPC API](xmlrpc-api.md)
	- Ruby client example (inlined at the end)
- [Realtime P2P API](realtime-p2p-api.md)
- [P2P WebSocket message types](p2p-ws-message-types.yml)

### Glass system and visual effects

- [Glass system](glass-system.md)
- [Simplified glass system](simplified-glass-system.md)
- [Enhanced glass fallback system](enhanced-glass-fallback-system.md)
- [Enhanced glass fallback documentation](enhanced-glass-fallback-documentation.md)
- [Glass cleanup migration](glass-cleanup-migration.md)
- [Glass migration guide](glass-migration-guide.md)
- [Infinite-scale glass effects](infinite-scale-glass-effects.md)
- [Liquid glass optimisation guide](liquid-glass-optimization-guide.md)
- [WebGL context debug fix](webgl-context-debug-fix.md)
- [WebGL context emergency management](webgl-context-emergency-management.md)
- [Text glow effects](text-glow-effects.md)

### Performance and reliability

- [Enhanced caching](enhanced-caching.md)
- [Progressive indexing](progressive-indexing.md)
- [Maximum compression implementation](maximum-compression-implementation.md)
- [Rate limiting implementation](rate-limiting-implementation.md)
- [Logging](logging-1.md)

### Security, compliance, and federation

- [Security federation implementation](security-federation-implementation.md)
- [Active Hashcash integration](active-hashcash-integration.md)
- [403 handling (Progressive indexing governance)](progressive-indexing.md#403-forbidden-domain-blocking)
- [GDPR error tracking](gdpr-error-tracking.md)
- [Role/authorization integration (Rolify + CanCanCan)](rolify-cancancan-integration.md)
- [TOMs (Technical & Organisational Measures)](toms.md)
- [Federation overview](federation.md)

### Analytics, email, and UX enhancements

- [Umami analytics](umami-analytics.md)
- [Email configuration](email-configuration.md)
- [Email CSS inlining](email-css-inlining.md)

## ✍️ Authoring guidelines

To keep this corpus useful:

- Write actionable documentation (guides, specs, how-tos). Avoid change logs, status updates, or summaries without instructions.
- Prefer one topic per file, with a short “Overview”, “How it works”, and “How to use” structure.
- Include minimal, runnable examples when describing APIs or CLIs.
- Keep names descriptive and consistent; use lowercase-with-hyphens for new filenames.

## 🔄 Updating documentation

When updating docs:

- Ensure accuracy and keep examples current.
- Use consistent terminology.
- Link to related docs to help readers discover context.
- If removing outdated content, replace it with a pointer to the canonical document or delete it outright (don’t keep status-only notes).

Questions or suggestions? Open an issue or PR with your proposed changes.
