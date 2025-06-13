# ActivityPub Federation Implementation

Libreverse now supports ActivityPub federation, allowing experiences to be shared across different Libreverse instances while maintaining decentralized control.

## Features Implemented

### Core Federation

- **Experience Federation**: Share approved experiences across instances via ActivityPub
- **Custom ActivityPub Fields**: Extended ActivityPub with Libreverse-specific metadata for experiences
- **Cross-Instance Discovery**: Search and discover experiences from other Libreverse instances
- **Domain Blocking**: Admin tools to block problematic instances

### Custom ActivityPub Extensions

Libreverse extends ActivityPub with custom fields under the `https://libreverse.org/ns#` namespace:

- `libreverse:experienceType` - Type of experience (e.g., "interactive_html")
- `libreverse:author` - Experience author name
- `libreverse:approved` - Moderation approval status
- `libreverse:htmlContent` - URL to the HTML content
- `libreverse:moderationStatus` - Current moderation status
- `libreverse:interactionCapabilities` - Supported interaction types
- `libreverse:instanceDomain` - Origin instance domain
- `libreverse:creatorAccount` - Creator's account username
- `libreverse:tags` - Experience tags/hashtags

### API Support

#### GraphQL API

- Added `federate` parameter to experience create/update mutations
- All existing experience queries work with federated content

#### XML-RPC API

- `federation.search` - Search across federated instances
- `federation.discover_instances` - Find other Libreverse instances
- `federation.block_instance` - Block an instance (admin only)
- `federation.unblock_instance` - Unblock an instance (admin only)
- `federation.blocked_domains` - List blocked domains (admin only)
- `federation.stats` - Federation statistics (admin only)

#### ActivityPub Endpoints

- `/.well-known/libreverse` - Instance discovery endpoint
- `/api/activitypub/experiences` - Public experiences collection
- `/api/activitypub/search` - Public search endpoint

### User Interface

#### Experience Creation

- Federation toggle in experience forms (enabled by default)
- Only verified accounts can federate experiences
- Federation only occurs after admin approval

#### Search Integration

- Cross-instance search with `?federated=true` parameter
- Federated results are clearly marked with source instance
- Local results prioritized over federated results

#### Admin Interface

- Federation management dashboard at `/admin/federation`
- Domain blocking/unblocking tools
- Federation statistics and monitoring
- Federated experience management

### Moderation Integration

#### Content Moderation

- Existing moderation rules apply to federated content
- Incoming reports handled via ActivityPub Flag activities
- Domain-level blocking for problematic instances

#### Report Handling

- Federated reports create local moderation logs
- Admin notifications for cross-instance reports
- Integration with existing moderation workflows

## Configuration

### Environment Variables

- `INSTANCE_DOMAIN` - Your instance's domain (e.g., "my-libreverse.com")

### Federation Settings

Federation is configured in `config/initializers/federails.rb` and enabled by default. The configuration automatically adapts to different Rails environments:

- **Development**: HTTP localhost with port 3000
- **Test**: HTTP localhost without port
- **Production**: HTTPS with SSL enforcement and the configured instance domain

Key configuration options include:

```ruby
Federails.configure do |config|
  config.app_name = "Libreverse"
  config.enable_discovery = true
  config.open_registrations = true
  config.force_ssl = true # in production
  # ... environment-specific settings
end
```

## Security Considerations

### Content Validation

- All federated content is validated against local moderation rules
- HTML content from other instances is sandboxed
- Malicious instances can be blocked at the domain level

### Privacy Protection

- Only approved, public experiences are federated
- User account information is not shared beyond public profile data
- Federation can be disabled per-experience or instance-wide

## Development and Testing

### Running Federation Locally

1. Set `INSTANCE_DOMAIN=localhost:3000` in development
2. Use ngrok or similar for testing cross-instance federation
3. Federation jobs run synchronously in development for easier debugging

### Database Migrations

The following tables were added for federation:

- `federails_actors` - ActivityPub actor representations
- `federails_activities` - ActivityPub activities log
- `federails_followings` - Following relationships
- `federails_moderation_reports` - Federated reports
- `federails_moderation_domain_blocks` - Blocked domains

New columns added to `experiences`:

- `federate` (boolean) - Whether to federate this experience
- `federated_blocked` (boolean) - Whether experience is blocked due to domain blocking

## Future Enhancements

### Planned Features

- User following across instances
- Real-time federated notifications
- Federated comments and reactions
- Enhanced discovery algorithms
- Federation analytics dashboard

### Protocol Extensions

- Rich media support in federated experiences
- Collaborative experience editing across instances
- Federated user authentication (OIDC)
- Advanced content synchronization

## Troubleshooting

### Common Issues

#### Federation Not Working

1. Check that `INSTANCE_DOMAIN` is set correctly
2. Verify SSL certificates in production
3. Ensure firewall allows ActivityPub traffic (HTTP/HTTPS)
4. Check `federails_actors` table has entries for local accounts

#### Blocked Content

1. Check domain blocking list in admin interface
2. Verify experience approval status
3. Check moderation logs for rejection reasons

#### Performance Issues

1. Monitor federation job queue
2. Consider rate limiting for federated requests
3. Optimize database queries for large federated datasets

For more detailed information, see the Federails documentation at <https://gitlab.com/experimentslabs/federails>
