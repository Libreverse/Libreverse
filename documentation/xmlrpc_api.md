# Libreverse XML-RPC API Documentation

This document describes the secure XML-RPC API for Libreverse.

## Overview

The Libreverse API uses XML-RPC over HTTPS for secure, reliable communication. XML-RPC is a remote procedure call protocol which uses XML to encode its calls and HTTP as a transport mechanism.

## Authentication

API access requires authentication through session cookies. You must obtain a valid session by logging in through the web interface or by using guest credentials where appropriate. The session cookie must be included in all API requests.

## Endpoint

All XML-RPC calls should be made to the following endpoint:

```http
https://libreverse.dev/api/xmlrpc
```

## Security Measures

The API implements multiple security mechanisms:

- All requests must be made over HTTPS
- Rate limiting is enforced to prevent abuse
- Authentication is required for all methods
- Input validation is performed on all parameters
- Full audit logging of all API calls

## Available Methods

### preferences.isDismissed

Checks if a specific preference has been dismissed by the user.

**Parameters:**

- `key` (string): The preference key to check

**Returns:**

- `boolean`: True if the preference has been dismissed, false otherwise

**Example request:**

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.isDismissed</methodName>
  <params>
    <param>
      <value><string>dashboard-tutorial</string></value>
    </param>
  </params>
</methodCall>
```

**Example response:**

```xml
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><boolean>1</boolean></value>
    </param>
  </params>
</methodResponse>
```

### preferences.dismiss

Dismisses a specific preference for the user.

**Parameters:**

- `key` (string): The preference key to dismiss

**Returns:**

- `boolean`: True if the dismissal was successful

**Example request:**

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.dismiss</methodName>
  <params>
    <param>
      <value><string>dashboard-tutorial</string></value>
    </param>
  </params>
</methodCall>
```

**Example response:**

```xml
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><boolean>1</boolean></value>
    </param>
  </params>
</methodResponse>
```

## Error Handling

Errors are returned as XML-RPC fault responses with a fault code and fault string.

**Example error response:**

```xml
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>400</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Invalid preference key</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
```

## Common Fault Codes

- `400`: Bad request (e.g., invalid parameters)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (access denied)
- `404`: Method not found
- `429`: Rate limit exceeded
- `500`: Internal server error

## Client Implementation Examples

See `xmlrpc_client_example.rb` for a complete Ruby client implementation example.
