# Progressive Indexing System

The Decentraland indexer now supports progressive indexing, which allows it to slowly expand its coverage of the Decentraland world over time instead of being limited to a fixed set of coordinates.

## How it Works

### Spiral Expansion

- **Starting Point**: Genesis Plaza (0,0) - the main spawn area
- **Pattern**: Expands outward in a spiral pattern
- **Radius Growth**: Starts with radius 5, expands by 5 each time the current area is exhausted
- **Maximum**: Caps at radius 50 to prevent excessive API calls

### Daily Limits

- **Production**: 100 items per day
- **Development**: 20 items per day (for testing)
- **Per Run**: Still respects `max_items` limit (50 in production, 10 in development)

### Smart Coordinate Selection

1. **Unindexed Priority**: Only fetches coordinates that haven't been indexed yet
2. **High-Value Fallback**: If spiral area is exhausted, includes known high-traffic areas
3. **Persistent State**: Remembers progress between runs using Rails cache

## Configuration

```yaml
# config/indexers.yml
decentraland:
    daily_limit: 100 # Maximum items per day
    max_items: 50 # Maximum items per run
    schedule: "0 */12 * * *" # Run every 12 hours
```

## Monitoring

### Admin Interface

- View daily progress and limits in `/admin/indexers/decentraland`
- Shows current search radius and total indexed scenes
- Progress bar for daily limit

### Rake Tasks

```bash
# Test progressive indexing without running
rake indexing:test_progressive

# Show detailed statistics
rake indexing:progressive_stats

# Reset search radius (for testing)
rake indexing:reset_progressive
```

## Benefits

1. **Sustainable Growth**: Limits daily API usage while continuously expanding coverage
2. **No Waste**: Avoids re-indexing the same coordinates repeatedly
3. **Smart Expansion**: Prioritizes areas more likely to have content
4. **Fault Tolerant**: Handles empty areas gracefully without stopping
5. **Configurable**: Easy to adjust limits via configuration

## Behavior

- **Daily Limit Reached**: Indexer will skip running until the next day
- **Area Exhausted**: Automatically expands search radius and continues
- **Empty Coordinates**: Logs warnings but continues (normal for unexplored areas)
- **High-Value Areas**: Always checks popular districts even outside current spiral

This system ensures that over time, the indexer will eventually cover the entire active areas of Decentraland while respecting API limits and being efficient with resources.
