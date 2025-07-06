# Search Functionality

## Overview

The search feature in Libreverse allows users to discover experiences based on various criteria. It provides a fast, intuitive interface for finding relevant content within the platform.

## Search Capabilities

### Basic Search

- **Keyword Search**: Find experiences by entering relevant terms
- **Title Matching**: Prioritizes matches in experience titles
- **Content Matching**: Also searches within experience descriptions and content
- **Author Search**: Find experiences by a specific creator

### Search Interface

The search interface includes:

- **Search Bar**: Prominent, accessible from all main pages via the sidebar
- **Instant Results**: Real-time suggestions as you type
- **Filtering Options**: Narrow results by various attributes
- **Sorting Controls**: Order results by relevance, date, or popularity

## User Flow

1. **Initiating Search**:
    - Users can access search via the sidebar navigation
    - The search page presents a clear, focused search interface
    - Direct URL access is available via `/search`

2. **Performing Searches**:
    - Enter search terms in the query field
    - Optionally apply filters
    - Submit search or use real-time suggestions

3. **Viewing Results**:
    - Results display in a grid or list format
    - Each result shows the experience title, author, and brief description
    - Pagination controls for navigating through multiple pages of results

4. **Refining Searches**:
    - Modify search terms without losing context
    - Add or remove filters to narrow results
    - Change sort order to find most relevant experiences

## Technical Implementation

The search functionality is implemented through:

- The `SearchController` which processes search requests
- Full-text search capabilities at the database level
- Frontend components for real-time interaction
- Caching mechanisms for performance optimization

### Controller Logic

The search controller processes requests with this flow:

1. Receive search parameters from the request
2. Validate and sanitize input
3. Execute the search query against the database
4. Format and return results
5. Handle pagination and sorting

### Query Processing

Searches are processed with these priorities:

- Exact matches on title
- Partial matches on title
- Matches on author name
- Matches in description
- Matches in content

Results are ranked by relevance score and then by recency.

## Performance Considerations

The search functionality includes several optimizations:

- **Database Indexing**: Full-text indexes on searchable fields
- **Result Caching**: Common searches are cached
- **Pagination**: Results are paginated to limit resource usage
- **Debouncing**: Frontend implements typing debounce to reduce server load

## Examples

### Search Examples

```http
GET /search?query=virtual+reality
```

Returns experiences with "virtual reality" in their title, description, or content.

### Author Search

```http
GET /search?query=author:johndoe
```

Returns experiences created by "johndoe".

## Future Enhancements

Planned improvements to the search functionality include:

- Advanced filtering by experience attributes
- Tag-based searching
- Category browsing
- Saved searches for authenticated users
- Search history for returning users
