# Advanced WebGL Context Management - Emergency Prevention Guide

## Overview

This guide outlines the advanced WebGL context management system designed to prevent context overloading and maintain stable performance with many concurrent glass effects.

## Quick fixes summary (from debug investigations)

Field fixes we’ve applied and validated:

- Reduce max contexts (12 → 8) and pool size (6 → 4)
- Lower active rendering instances (8 → 6)
- Increase cleanup cadence (5s → 3s)
- Immediate visibility check + larger root margin for earlier init
- Timeout fallback to ensure eager initialization when intersection is late
- Add double-check before context creation to avoid oversubscription

New default configuration (effective baseline):

```javascript
optimizedWebGLContextManager.maxContexts = 8; // was 12
optimizedWebGLContextManager.maxPoolSize = 4; // was 6
optimizedWebGLContextManager.cleanupInterval = 3000; // was 5000ms

Container.maxConcurrentInstances = 8; // was 12
Container.maxActiveRenderingInstances = 6; // was 8

webglContextMonitor.warningThreshold = 6; // was 8
webglContextMonitor.criticalThreshold = 8; // was 10
```

These tie directly into the emergency prevention system below.

## Emergency Prevention System

### 1. WebGL Context Monitor (`webgl_context_monitor.js`)

**Real-time Monitoring:**

- Checks context health every 2 seconds
- Tracks context creation rate (max 3/second)
- Monitors total active contexts vs. critical thresholds

**Alert Levels:**

- **Normal**: < 8 active contexts
- **Warning**: 8-9 active contexts (preventive measures activated)
- **Critical**: 10+ active contexts (emergency measures activated)

**Emergency Response:**

```javascript
// Critical situation handling
if (contexts >= 10) {
  1. Force aggressive cleanup
  2. Activate emergency pause (5 seconds)
  3. Release 50% of background instances
  4. Force release oldest contexts if still critical
}
```

### 2. Reduced Capacity Limits

**WebGL Context Manager:**

- Maximum contexts: 12 (reduced from 16)
- Context pool size: 6 (reduced from 8)
- More aggressive cleanup every 5 seconds

**Container Limits:**

- Maximum concurrent containers: 12 (reduced from 16)
- Maximum actively rendering: 8
- Background instances have reduced render frequency

**Glass Render Manager Quality Levels:**

```javascript
qualityLevels: {
  high: { maxInstances: 8, tintOpacity: 1.0 },    // was 20
  medium: { maxInstances: 16, tintOpacity: 0.8 },  // was 35
  low: { maxInstances: 24, tintOpacity: 0.6 }      // was 50
}
```

### 3. Priority-Based Rendering System

**Visibility-Based Priority:**

- Only 8 containers can actively render at once
- Visible containers get priority over background ones
- Background containers render at reduced frequency (100ms delay)

**Intersection Observer Integration:**

- Tracks visibility changes in real-time
- Automatically promotes/demotes containers based on visibility
- Uses 50px root margin for early detection

## Usage and Monitoring

### Real-Time Stats

```javascript
// Get comprehensive system status
const stats = Container.getStats();
console.log("Container Stats:", {
    active: stats.activeInstances,
    rendering: stats.activeRenderingInstances,
    background: stats.backgroundInstances,
    queued: stats.queuedCreations,
});

// WebGL context status
console.log("WebGL Stats:", stats.webglStats);

// Emergency monitoring status
console.log("Monitor Stats:", stats.monitoringStats);
```

### Emergency Monitoring Dashboard

```javascript
// Check if emergency measures are active
const monitoring = webglContextMonitor.getMonitoringStats();
if (monitoring.emergencyCleanupActive) {
    console.warn("🚨 Emergency cleanup in progress");
}
if (monitoring.emergencyPauseActive) {
    console.warn("⏸️ Emergency pause active - new containers blocked");
}
```

### Manual Emergency Response

```javascript
// Force immediate cleanup if needed
optimizedWebGLContextManager.aggressiveCleanup();

// Force release oldest contexts
optimizedWebGLContextManager.forceReleaseOldestContexts(3);

// Check current context health
webglContextMonitor.checkContextHealth();
```

## Configuration Options

### Adjust Thresholds

```javascript
// Modify warning/critical thresholds
webglContextMonitor.warningThreshold = 6; // Default: 8
webglContextMonitor.criticalThreshold = 8; // Default: 10

// Adjust cleanup frequency
optimizedWebGLContextManager.cleanupInterval = 3000; // Default: 5000ms
```

### Performance Modes

```javascript
// Emergency performance mode
glassRenderManager.setPerformanceMode("performance"); // Reduces quality, increases capacity

// Conservative mode for stability
Container.maxConcurrentInstances = 8;
Container.maxActiveRenderingInstances = 4;
```

## Troubleshooting

### If Context Warnings Still Occur

1. **Check Current Usage:**

    ```javascript
    const stats = Container.getStats();
    console.log(
        `Using ${stats.webglStats.activeContexts}/${stats.webglStats.maxContexts} contexts`,
    );
    ```

2. **Force Emergency Cleanup:**

    ```javascript
    webglContextMonitor.handleCriticalSituation();
    ```

3. **Reduce Limits Further:**

    ```javascript
    optimizedWebGLContextManager.maxContexts = 8;
    Container.maxConcurrentInstances = 8;
    ```

4. **Enable Debug Logging:**

    ```javascript
    // Monitor will log all context operations
    webglContextMonitor.startMonitoring();
    ```

### Performance Issues

1. **Too Many Background Instances:**
    - Check `stats.backgroundInstances` - should be < 16
    - Ensure visibility detection is working properly

2. **High Creation Rate:**
    - Monitor `monitoring.contextCreationRate` - should be < 3/second
    - Emergency pause will activate if exceeded

3. **Memory Leaks:**
    - Ensure containers are properly destroyed
    - Check for disconnected elements holding contexts

## Best Practices

### 1. Design Patterns

- Limit visible glass effects to 6-8 at once
- Use glass effects primarily for critical UI elements
- Consider non-glass alternatives for decorative elements

### 2. Implementation

- Always use `Container.createContainer()` (returns promise)
- Implement proper cleanup in component destroy methods
- Monitor stats during development

### 3. Performance Monitoring

- Set up periodic health checks in production
- Log emergency activations for debugging
- Monitor context creation patterns

### 4. Fallback Strategies

- Implement CSS fallbacks for glass effects
- Gracefully degrade quality under load
- Provide user option to disable glass effects

## Emergency Contacts

If context overloading persists despite these measures:

1. Check browser DevTools for WebGL errors
2. Monitor `webglContextMonitor.getMonitoringStats()`
3. Consider reducing `maxContexts` to 6-8 for stability
4. Implement manual context release triggers in UI

This system provides multiple layers of protection against WebGL context exhaustion while maintaining the visual quality of glass effects where they matter most.
