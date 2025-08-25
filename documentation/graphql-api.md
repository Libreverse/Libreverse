# GraphQL API Documentation

## Overview

The GraphQL API provides a modern, flexible interface for accessing all application functionality. It supports both queries (read operations) and mutations (write operations) with comprehensive authentication and authorization.

## Endpoint

- **URL**: `POST /graphql`
- **Content-Type**: `application/json` or `application/graphql`
- **Rate Limit**: 100 requests per minute per IP address

## Authentication

### Session-Based Authentication

The API uses session-based authentication. Users must be logged in through the web interface to access authenticated operations.

### CSRF Protection

All mutations (write operations) require a valid CSRF token in the `X-CSRF-Token` header. Queries (read operations) do not require CSRF tokens.

```javascript
// Example with CSRF token
fetch("/graphql", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
    },
    body: JSON.stringify({
        query: 'mutation { createExperience(title: "Test") { id } }',
    }),
});
```

## Schema Overview

### Types

#### Experience

```graphql
type Experience {
    id: ID!
    title: String!
    description: String
    author: String
    approved: Boolean!
    accountId: ID
    hasHtmlFile: Boolean!
    createdAt: String!
    updatedAt: String!
}
```

#### GraphqlAccount

```graphql
type GraphqlAccount {
    id: ID!
    username: String!
    admin: Boolean!
    guest: Boolean!
    status: String!
}
```

#### UserPreference

```graphql
type UserPreference {
    id: ID!
    accountId: ID!
    key: String!
    value: String
    createdAt: String!
    updatedAt: String!
}
```

#### ModerationLog

```graphql
type ModerationLog {
    id: ID!
    field: String!
    modelType: String!
    content: String!
    reason: String!
    accountId: ID
    violations: String
    createdAt: String!
}
```

## Queries (Read Operations)

### Public Queries (No Authentication Required)

#### Get All Experiences

```graphql
query {
    experiences(limit: 20, approvedOnly: true) {
        id
        title
        description
        author
        approved
        hasHtmlFile
        createdAt
    }
}
```

#### Get Single Experience

```graphql
query {
    experience(id: "1") {
        id
        title
        description
        author
        approved
        hasHtmlFile
        createdAt
    }
}
```

#### Get Approved Experiences

```graphql
query {
    approved(limit: 20) {
        id
        title
        description
        author
        createdAt
    }
}
```

#### Search Experiences

```graphql
query {
    searchExperiences(query: "search term", limit: 10) {
        id
        title
        description
        author
        createdAt
    }
}
```

### Authenticated Queries (Session Required)

#### Get Current User

```graphql
query {
    me {
        id
        username
        admin
        guest
        status
    }
}
```

#### Get User Preference

```graphql
query {
    getPreference(key: "theme-selection") {
        key
        value
    }
}
```

#### Check if Preference is Dismissed

```graphql
query {
    isDismissed(key: "welcome-message")
}
```

#### Get Pending Experiences

```graphql
query {
    pendingApproval(limit: 20) {
        id
        title
        description
        approved
        createdAt
    }
}
```

#### Get Moderation Logs

```graphql
query {
    moderationLogs(limit: 20) {
        id
        field
        modelType
        content
        reason
        createdAt
    }
}
```

## Mutations (Write Operations)

All mutations require authentication and CSRF tokens.

### Experience Operations

#### Create Experience

```graphql
mutation {
    createExperience(
        title: "My Experience"
        description: "A great experience"
        htmlContent: "<p>HTML content here</p>"
        author: "Author Name"
    ) {
        id
        title
        description
        approved
    }
}
```

#### Update Experience

```graphql
mutation {
    updateExperience(
        id: "1"
        title: "Updated Title"
        description: "Updated description"
    ) {
        id
        title
        description
        updatedAt
    }
}
```

#### Delete Experience

```graphql
mutation {
    destroyExperience(id: "1")
}
```

#### Approve Experience (Admin Only)

```graphql
mutation {
    approveExperience(id: "1") {
        id
        approved
    }
}
```

### User Preference Operations

#### Set Preference

```graphql
mutation {
    setPreference(key: "theme-selection", value: "dark") {
        key
        value
    }
}
```

#### Dismiss Preference

```graphql
mutation {
    dismissPreference(key: "welcome-message")
}
```

## Access Levels

### Public Access

- `experiences` - Get all experiences (approved only for non-admins)
- `experience` - Get single experience (approved only for non-admins)
- `approved` - Get approved experiences
- `searchExperiences` - Search experiences

### Authenticated Access

- `me` - Get current user information
- `getPreference` - Get user preference
- `isDismissed` - Check if preference is dismissed
- `pendingApproval` - Get pending experiences (own experiences for users, all for admins)
- `moderationLogs` - Get moderation logs (own logs for users, all for admins)
- `createExperience` - Create new experience
- `updateExperience` - Update own experience
- `destroyExperience` - Delete own experience
- `setPreference` - Set user preference
- `dismissPreference` - Dismiss user preference

### Admin Access

- `approveExperience` - Approve any experience
- All authenticated operations with elevated privileges

## Error Handling

The API returns errors in the standard GraphQL format:

```json
{
    "errors": [
        {
            "message": "Authentication required",
            "path": ["me"]
        }
    ]
}
```

### Common Error Messages

- `"Authentication required"` - User must be logged in
- `"Admin access required"` - Operation requires admin privileges
- `"CSRF token missing or invalid"` - Mutation requires valid CSRF token
- `"Rate limit exceeded"` - Too many requests
- `"Experience not found"` - Requested experience doesn't exist
- `"Invalid preference key"` - Preference key not in allowed list

## Rate Limiting

- **Limit**: 100 requests per minute per IP address
- **Response**: HTTP 429 with error message when exceeded
- **Headers**: No rate limit headers are currently provided

## Allowed Preference Keys

User preferences are restricted to these keys:

- `dashboard-tutorial`
- `search-tutorial`
- `welcome-message`
- `feature-announcement`
- `theme-selection`
- `sidebar_expanded`
- `sidebar_hovered`
- `drawer_expanded_main`
- `locale`

## Example Client Implementation

### JavaScript/TypeScript Client

```javascript
class GraphQLClient {
    constructor(endpoint = "/graphql") {
        this.endpoint = endpoint;
        this.csrfToken = document.querySelector(
            'meta[name="csrf-token"]',
        )?.content;
    }

    async query(query, variables = {}) {
        const response = await fetch(this.endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
            },
            body: JSON.stringify({ query, variables }),
        });

        return response.json();
    }

    async mutate(mutation, variables = {}) {
        const response = await fetch(this.endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
                "X-CSRF-Token": this.csrfToken,
            },
            body: JSON.stringify({ query: mutation, variables }),
        });

        return response.json();
    }

    // Helper methods
    async getExperiences(limit = 20) {
        return this.query(
            `
      query GetExperiences($limit: Int) {
        experiences(limit: $limit) {
          id
          title
          description
          author
          approved
          createdAt
        }
      }
    `,
            { limit },
        );
    }

    async createExperience(title, description, htmlContent, author) {
        return this.mutate(
            `
      mutation CreateExperience($title: String!, $description: String, $htmlContent: String, $author: String) {
        createExperience(title: $title, description: $description, htmlContent: $htmlContent, author: $author) {
          id
          title
          description
          approved
        }
      }
    `,
            { title, description, htmlContent, author },
        );
    }

    async getCurrentUser() {
        return this.query(`
      query {
        me {
          id
          username
          admin
          status
        }
      }
    `);
    }

    async setPreference(key, value) {
        return this.mutate(
            `
      mutation SetPreference($key: String!, $value: String!) {
        setPreference(key: $key, value: $value) {
          key
          value
        }
      }
    `,
            { key, value },
        );
    }
}

// Usage
const client = new GraphQLClient();

// Get experiences
const experiences = await client.getExperiences(10);

// Create experience
const newExperience = await client.createExperience(
    "My Experience",
    "Description",
    "<p>HTML content</p>",
    "Author",
);

// Get current user
const user = await client.getCurrentUser();

// Set preference
await client.setPreference("theme-selection", "dark");
```

## Security Features

1. **CSRF Protection**: All mutations require valid CSRF tokens
2. **Rate Limiting**: 100 requests per minute per IP
3. **Authentication**: Session-based authentication for protected operations
4. **Authorization**: Role-based access control (user vs admin)
5. **Input Validation**: All inputs are validated and sanitized
6. **SQL Injection Protection**: Parameterized queries and sanitization
7. **Content Moderation**: Automatic content filtering on user-generated content

## Performance Considerations

1. **Query Limits**: All list queries have configurable limits (max 100)
2. **Efficient Queries**: Use specific field selection to minimize data transfer
3. **Caching**: Consider implementing client-side caching for frequently accessed data
4. **Pagination**: Use limit parameters for large datasets

## Migration from Other APIs

If migrating from the XML-RPC or JSON APIs:

### From XML-RPC

- Replace method calls with GraphQL queries/mutations
- Use field selection instead of getting all data
- Handle errors through GraphQL error format

### From JSON API

- Replace REST endpoints with GraphQL queries/mutations
- Combine multiple requests into single GraphQL queries
- Use GraphQL variables instead of URL parameters

## Introspection

The GraphQL schema supports introspection for development:

```graphql
query {
    __schema {
        types {
            name
            description
        }
    }
}
```

Note: Introspection may be disabled in production environments for security.
