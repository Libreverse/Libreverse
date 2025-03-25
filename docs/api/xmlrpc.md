# XML-RPC API Reference

This document describes the XML-RPC API endpoints available in Libreverse.

## Endpoint

All XML-RPC requests should be sent to:

```
POST /api/xmlrpc
```

## Authentication

Some API methods require authentication while others are public. Public methods are identified in each method's documentation.

## Methods

### preferences.isDismissed

Check if a preference has been dismissed.

- **Authentication**: Public
- **Parameters**:
    - `preference_key` (string): The key of the preference to check
- **Returns**: Boolean (true if dismissed, false otherwise)

Example:

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.isDismissed</methodName>
  <params>
    <param>
      <value><string>welcome_banner</string></value>
    </param>
  </params>
</methodCall>
```

### preferences.dismiss

Dismiss a preference.

- **Authentication**: Public
- **Parameters**:
    - `preference_key` (string): The key of the preference to dismiss
- **Returns**: Boolean (true if successful)

Example:

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.dismiss</methodName>
  <params>
    <param>
      <value><string>welcome_banner</string></value>
    </param>
  </params>
</methodCall>
```

### experiences.all

Get all experiences on the instance, sorted by most recent first.

- **Authentication**: Public
- **Parameters**: None
- **Returns**: Array of experience objects with the following properties:
    - `id` (int): The ID of the experience
    - `title` (string): The title of the experience
    - `description` (string): The description of the experience
    - `author` (string): The author of the experience
    - `content` (string): The content of the experience
    - `created_at` (string): ISO8601 formatted creation timestamp
    - `updated_at` (string): ISO8601 formatted last update timestamp

Example:

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>experiences.all</methodName>
  <params>
  </params>
</methodCall>
```

Example response:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <params>
    <param>
      <value>
        <array>
          <data>
            <value>
              <struct>
                <member>
                  <name>id</name>
                  <value><int>1</int></value>
                </member>
                <member>
                  <name>title</name>
                  <value><string>Experience Title</string></value>
                </member>
                <member>
                  <name>description</name>
                  <value><string>Experience Description</string></value>
                </member>
                <member>
                  <name>author</name>
                  <value><string>Experience Author</string></value>
                </member>
                <member>
                  <name>content</name>
                  <value><string>Experience Content</string></value>
                </member>
                <member>
                  <name>created_at</name>
                  <value><string>2023-08-15T12:34:56Z</string></value>
                </member>
                <member>
                  <name>updated_at</name>
                  <value><string>2023-08-15T12:34:56Z</string></value>
                </member>
              </struct>
            </value>
          </data>
        </array>
      </value>
    </param>
  </params>
</methodResponse>
```

## Error Handling

When an error occurs, the XML-RPC API returns a fault response. The response contains a faultCode (integer) and a faultString (string) describing the error.

Example error response:

```xml
<?xml version="1.0" encoding="UTF-8"?>
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
          <value><string>Invalid XML-RPC request</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
```

Common fault codes:

- 400: Bad Request (invalid XML, invalid method name)
- 401: Unauthorized (authentication required)
- 413: Request Entity Too Large
- 429: Rate Limit Exceeded
- 500: Internal Server Error
