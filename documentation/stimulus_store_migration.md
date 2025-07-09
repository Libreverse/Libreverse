# Stimulus Store Migration Guide

This guide explains how to migrate from the existing Stimulus controllers to the new enhanced controllers that use stimulus-store for centralized state management.

## Overview

The stimulus-store library provides a lightweight, atomic state management solution for Stimulus controllers. It allows you to:

- **Share state between controllers**: Multiple controllers can access and modify the same state
- **Centralize state management**: Keep related state in dedicated stores rather than scattered across controllers
- **Reactive updates**: Controllers automatically update when store values change
- **Persistent state**: Easily save and restore state across sessions
- **Better debugging**: All state changes are centralized and trackable

## Stores Overview

### Available Stores

1. **themeStore** - App-wide theme and UI preferences
2. **glassConfigStore** - Glass effect configuration
3. **navigationStore** - Navigation state and current page
4. **instanceSettingsStore** - Instance configuration settings
5. **toastStore** - Toast notifications management
6. **experienceStore** - Experience/content state
7. **searchStore** - Search and filtering state

### Store Structure

Each store contains:

- `name`: Unique identifier
- `type`: Data type (Object, String, Number, etc.)
- `initialValue`: Default state
- `value`: Current state (reactive)

## Migration Steps

### Step 1: Update Controller Imports

Replace your existing controller imports with enhanced versions:

```javascript
// Before
import GlassController from "./glass_controller";

// After
import EnhancedGlassController from "./enhanced_glass_controller";
```

### Step 2: Update HTML Data Attributes

Replace controller names in your HTML:

```html
<!-- Before -->
<div data-controller="glass" data-glass-border-radius-value="20">
    <!-- After -->
    <div
        data-controller="enhanced-glass"
        data-enhanced-glass-border-radius-value="20"
    ></div>
</div>
```

### Step 3: Update Controller Registration

Update your controller registration in `app/javascript/controllers/index.js`:

```javascript
// Before
import GlassController from "./glass_controller";
application.register("glass", GlassController);

// After
import EnhancedGlassController from "./enhanced_glass_controller";
application.register("enhanced-glass", EnhancedGlassController);
```

## Controller-Specific Migration

### Glass Controller → Enhanced Glass Controller

The enhanced glass controller uses centralized glass configuration:

#### Before (glass_controller.coffee)

```coffeescript
@values = {
  borderRadius: { type: Number, default: 20 },
  tintOpacity: { type: Number, default: 0.12 },
  glassType: { type: String, default: "rounded" },
  # ... other values
}
```

#### After (enhanced_glass_controller.coffee)

```coffeescript
@stores = [themeStore, glassConfigStore, navigationStore]

# Values are now managed in glassConfigStore
# Access via @glassConfigStoreValue.borderRadius
```

#### Benefits

- **Shared configuration**: All glass elements use the same config
- **Dynamic updates**: Change glass settings globally
- **Theme integration**: Glass effects respond to theme changes

### Instance Settings Controller → Enhanced Instance Settings Controller

The enhanced version provides optimistic updates and auto-save:

#### Before (instance_settings_controller.coffee)

```coffeescript
toggleAutomoderation: (event) ->
  event.preventDefault()
  @stimulate('InstanceSettings#toggle_automoderation')
```

#### After (enhanced_instance_settings_controller.coffee)

```coffeescript
toggleAutomoderation: (event) ->
  event.preventDefault()

  # Optimistic update
  settings = @instanceSettingsStoreValue
  newValue = not settings.automoderation

  @instanceSettingsStoreValue = {
    ...settings,
    automoderation: newValue,
    isDirty: true
  }

  # Auto-save or immediate save
  unless @autoSaveValue
    @stimulate('InstanceSettings#toggle_automoderation')
```

#### Migration Benefits

- **Optimistic updates**: UI responds immediately
- **Auto-save**: Configurable auto-save functionality
- **Validation**: Built-in form validation
- **State tracking**: Know when settings are dirty or loading

### Toast Controller → Enhanced Toast Controller

The enhanced version provides centralized toast management:

#### Before (toast_controller.coffee)

```coffeescript
# Individual toast management
@values = { timeout: { type: Number, default: 5000 } }
```

#### After (enhanced_toast_controller.coffee)

```coffeescript
# Centralized toast state
@stores = [toastStore]

# Access to global toast management
@toastStoreValue.toasts # All active toasts
@toastStoreValue.maxToasts # Maximum number of toasts
```

#### Toast Store Benefits

- **Global toast management**: Control all toasts from one place
- **Toast queue**: Automatic management of multiple toasts
- **Enhanced animations**: Better animation and positioning
- **Accessibility**: Improved keyboard and screen reader support

## Using Store Utilities

### StoreManager

Access all stores and perform bulk operations:

```javascript
import { storeManager } from "./stores/utilities";

// Get all store values
const allStores = storeManager.getAllStoreValues();

// Reset all stores
storeManager.resetAllStores();

// Save state to localStorage
storeManager.saveToLocalStorage();

// Load state from localStorage
storeManager.loadFromLocalStorage();

// Subscribe to store changes
const unsubscribe = storeManager.subscribeToStore(
    "theme",
    (newValue, oldValue) => {
        console.log("Theme changed:", newValue);
    },
);
```

### ToastManager

Easily show toast notifications:

```javascript
import { toastManager } from "./stores/utilities";

// Show different types of toasts
toastManager.success("Settings saved successfully!");
toastManager.error("Failed to save settings");
toastManager.warning("Please check your input");
toastManager.info("Processing your request...");

// Custom toast with options
toastManager.show("Custom message", "info", {
    timeout: 10000,
    showProgress: true,
});
```

### ThemeManager

Manage app-wide theme settings:

```javascript
import { themeManager } from "./stores/utilities";

// Toggle theme features
themeManager.toggleDarkMode();
themeManager.toggleGlass();
themeManager.toggleAnimations();

// Check current theme state
if (themeManager.isDarkMode()) {
    // Dark mode is enabled
}

if (themeManager.isGlassEnabled()) {
    // Glass effects are enabled
}
```

## HTML Template Updates

### Enhanced Glass Controller

```html
<!-- Before -->
<nav
    data-controller="glass"
    data-glass-component-type-value="nav"
    data-glass-border-radius-value="20"
>
    <!-- nav content -->
</nav>

<!-- After -->
<nav
    data-controller="enhanced-glass"
    data-enhanced-glass-component-type-value="nav"
>
    <!-- nav content -->
    <!-- Border radius now comes from glassConfigStore -->
</nav>
```

### Enhanced Instance Settings Controller

```html
<!-- Before -->
<form data-controller="instance-settings">
    <input
        type="checkbox"
        data-action="click->instance-settings#toggleAutomoderation"
    />
</form>

<!-- After -->
<form
    data-controller="enhanced-instance-settings"
    data-enhanced-instance-settings-auto-save-value="true"
>
    <input
        type="checkbox"
        data-action="click->enhanced-instance-settings#toggleAutomoderation"
    />
</form>
```

### Enhanced Toast Controller

```html
<!-- Before -->
<div data-controller="toast" data-toast-timeout-value="5000">Toast message</div>

<!-- After -->
<div
    data-controller="enhanced-toast"
    data-enhanced-toast-toast-id-value="123"
    data-enhanced-toast-type-value="success"
>
    Toast message
</div>
```

## Advanced Usage

### Custom Store Integration

Create custom stores for your specific needs:

```javascript
// Create custom store
import { createStore } from "stimulus-store"

export const myCustomStore = createStore({
  name: "myCustom",
  type: Object,
  initialValue: {
    customProperty: "default value"
  }
})

// Use in controller
import { myCustomStore } from "../stores/custom"

export default class extends Controller {
  @stores = [myCustomStore]

  connect() {
    useStore(this)
    console.log(this.myCustomStoreValue)
  }
}
```

### Store Synchronization

Keep stores in sync with server state:

```javascript
// In your controller
syncWithServer() {
  fetch('/api/settings')
    .then(response => response.json())
    .then(data => {
      this.instanceSettingsStoreValue = {
        ...this.instanceSettingsStoreValue,
        ...data
      }
    })
}
```

### Debugging

Access stores from browser console:

```javascript
// Available in browser console
LibreverseStores.manager.getAllStoreValues();
LibreverseStores.theme.toggleDarkMode();
LibreverseStores.toast.success("Debug message");
```

## Best Practices

1. **Use stores for shared state**: If multiple controllers need the same data, use a store
2. **Keep stores flat**: Avoid deeply nested objects in stores
3. **Use descriptive names**: Store names should clearly indicate their purpose
4. **Initialize stores early**: Set up stores in your application controller
5. **Handle errors gracefully**: Always handle store update errors
6. **Use utilities**: Leverage provided utility classes for common operations
7. **Document custom stores**: Document any custom stores you create

## Troubleshooting

### Common Issues

1. **Store not updating**: Make sure you're using `useStore(this)` in your controller
2. **Events not firing**: Check that store names match between definition and usage
3. **Performance issues**: Avoid frequent store updates in loops
4. **Memory leaks**: Clean up store listeners in disconnect()

### Migration Checklist

- [ ] Install stimulus-store package
- [ ] Create store definitions
- [ ] Update controller imports
- [ ] Update HTML data attributes
- [ ] Update controller registration
- [ ] Test all functionality
- [ ] Update documentation

## Examples

See the enhanced controllers in `app/javascript/controllers/` for complete examples:

- `enhanced_application_controller.coffee` - Base controller setup
- `enhanced_glass_controller.coffee` - Glass effects with stores
- `enhanced_instance_settings_controller.coffee` - Form state management
- `enhanced_toast_controller.coffee` - Toast notifications
- `enhanced_search_controller.coffee` - Search functionality

## Support

For questions or issues with the migration:

1. Check the stimulus-store documentation: <https://stimulus-store.com/>
2. Review the example controllers in this project
3. Use the browser console debugging tools
4. Check the store utilities for helper functions
