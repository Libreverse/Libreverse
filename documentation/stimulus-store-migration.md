# Stimulus Store System Guide

Centralized, reactive state for Stimulus controllers with lightweight persistence, shared state, and clean debugging.

## What Is stimulus-store?

stimulus-store is an atomic state container layer for Stimulus. It lets multiple controllers read/write shared state, react to changes, persist across sessions, and debug from a single place.

Key capabilities:

- Shared state across controllers
- Reactive updates with minimal code
- Optional persistence (e.g., localStorage)
- Centralized debugging and tooling

Install:

- bun add stimulus-store

## Core Concepts

- Store: Named, typed, reactive container
- Shape:
    - name: Unique store id
    - type: Data type (Object, String, Number, etc.)
    - initialValue: Default data
    - value: Current reactive value (accessed via controller accessors)
- Controller integration:
    - @stores = [storeA, storeB]
    - Use useStore(this) on connect
    - Access store with @storeNameStoreValue

## Stores In This App

- themeStore: Theme and UI preferences
- glassConfigStore: Glass effect configuration
- navigationStore: Navigation and current page
- instanceSettingsStore: Instance configuration and flags
- toastStore: Toasts list and options
- experienceStore: Experience/content state
- searchStore: Search and filtering state

## Creating A Store

```coffeescript
# app/javascript/stores/my_custom_store.coffee
import { createStore } from 'stimulus-store'

export const myCustomStore = createStore
    name: 'myCustom'
    type: Object
    initialValue:
        customProperty: 'default value'
```

## Using A Store In A Controller

```coffeescript
# app/javascript/controllers/example_controller.coffee
import { Controller } from '@hotwired/stimulus'
import { useStore } from 'stimulus-store'
import { myCustomStore } from '../stores/my_custom_store'

export default class extends Controller
    @stores = [myCustomStore]

    connect: ->
        useStore @
        console.log @myCustomStoreValue # => { customProperty: 'default value' }

    updateCustom: (event) ->
        @myCustomStoreValue =
            ...@myCustomStoreValue
            customProperty: event.target.value
```

Register (controllers/index.coffee):

```coffeescript
import { Application } from '@hotwired/stimulus'
import ExampleController from './example_controller'

application = Application.start()
application.register 'example', ExampleController
```

## HTML/HAML Integration

Prefer HAML for templates.

- Glass (centralized config via glassConfigStore)

```haml
/ Before
%nav{
    data: {
        controller: 'glass',
        'glass-component-type-value': 'nav',
        'glass-border-radius-value': '20'
    }
}

-# After
%nav{
    data: {
        controller: 'enhanced-glass',
        'enhanced-glass-component-type-value': 'nav'
    }
}
/ Border radius now comes from glassConfigStore
```

- Instance settings (optimistic updates + optional auto-save)

```haml
/ Before
%form{ data: { controller: 'instance-settings' } }
    %input{
        type: 'checkbox',
        data: { action: 'click->instance-settings#toggleAutomoderation' }
    }

/ After
%form{
    data: {
        controller: 'enhanced-instance-settings',
        'enhanced-instance-settings-auto-save-value': 'true'
    }
}
    %input{
        type: 'checkbox',
        data: { action: 'click->enhanced-instance-settings#toggleAutomoderation' }
    }
```

- Toasts (centralized toastStore)

```haml
/ Before
%div{ data: { controller: 'toast', 'toast-timeout-value': '5000' } } Toast message

/ After
%div{
    data: {
        controller: 'enhanced-toast',
        'enhanced-toast-toast-id-value': '123',
        'enhanced-toast-type-value': 'success'
    }
}
    Toast message
```

## Controller Patterns

- Centralized glass config (EnhancedGlassController)
    - @stores = [themeStore, glassConfigStore, navigationStore]
    - Read/write with @glassConfigStoreValue
- Optimistic settings (EnhancedInstanceSettingsController)
    - Toggle local value, mark isDirty, auto-save optional
    - Fall back to server call when auto-save is off
- Global toasts (EnhancedToastController)
    - @stores = [toastStore]
    - @toastStoreValue.toasts, @toastStoreValue.maxToasts

Example (optimistic toggle, CoffeeScript):

```coffeescript
toggleAutomoderation: (event) ->
    event.preventDefault()
    settings = @instanceSettingsStoreValue
    newValue = not settings.automoderation

    @instanceSettingsStoreValue =
        ...settings
        automoderation: newValue
        isDirty: true

    unless @autoSaveValue
        @stimulate 'InstanceSettings#toggle_automoderation'
```

## Utilities

StoreManager:

```coffeescript
import { storeManager } from './stores/utilities'

allStores = storeManager.getAllStoreValues()
storeManager.resetAllStores()
storeManager.saveToLocalStorage()
storeManager.loadFromLocalStorage()

unsubscribe = storeManager.subscribeToStore 'theme', (newValue, oldValue) ->
    console.log 'Theme changed:', newValue
```

ToastManager:

```coffeescript
import { toastManager } from './stores/utilities'

toastManager.success 'Settings saved successfully!'
toastManager.error 'Failed to save settings'
toastManager.warning 'Please check your input'
toastManager.info 'Processing your request...'

toastManager.show 'Custom message', 'info',
    timeout: 10000
    showProgress: true
```

ThemeManager:

```coffeescript
import { themeManager } from './stores/utilities'

themeManager.toggleDarkMode()
themeManager.toggleGlass()
themeManager.toggleAnimations()

if themeManager.isDarkMode()
    # Dark mode enabled

if themeManager.isGlassEnabled()
    # Glass effects enabled
```

## Persistence

- Use storeManager.saveToLocalStorage() and loadFromLocalStorage()
- Keep store shapes flat and serializable
- Consider versioning stored payloads to handle schema changes

## Server Sync

- Pull server state into stores
- Prefer backend StimulusReflex for authoritative changes, then reflect to stores

```coffeescript
# Controller: pull latest settings
syncWithServer: ->
    fetch('/api/settings')
        .then (r) -> r.json()
        .then (data) =>
            @instanceSettingsStoreValue =
                ...@instanceSettingsStoreValue
                ...data
```

With StimulusReflex (minimal sketch):

```coffeescript
# Controller
saveSettings: ->
    @stimulate 'InstanceSettings#save', @instanceSettingsStoreValue

# Reflex (Ruby) persists and broadcasts; controller updates store on receive.
```

## Debugging

From browser console:

```javascript
LibreverseStores.manager.getAllStoreValues();
LibreverseStores.theme.toggleDarkMode();
LibreverseStores.toast.success("Debug message");
```

## Best Practices

1. Use stores whenever state is shared across controllers
2. Keep stores flat; avoid deeply nested objects
3. Name stores and keys descriptively
4. Initialize core stores early (application controller)
5. Handle failures and rollbacks for optimistic updates
6. Use utilities (StoreManager/ToastManager/ThemeManager)
7. Document custom stores and their schema

## Troubleshooting

- Store not updating: Ensure useStore(this) is called in connect
- Events not firing: Verify store names match
- Performance: Avoid rapid updates in tight loops
- Memory leaks: Unsubscribe listeners in disconnect

## Checklist

- [ ] Install stimulus-store (bun add stimulus-store)
- [ ] Define stores (type + initialValue)
- [ ] Add @stores and useStore(this) in controllers
- [ ] Update templates to use enhanced controllers
- [ ] Wire persistence (optional)
- [ ] Add tests and docs

## Examples

See app/javascript/controllers/:

- enhanced_application_controller.coffee
- enhanced_glass_controller.coffee
- enhanced_instance_settings_controller.coffee
- enhanced_toast_controller.coffee
- enhanced_search_controller.coffee

## Reference

- stimulus-store docs: <https://stimulus-store.com/>
- Use HAML for templates, SCSS for styles, CoffeeScript for controllers
- Use bun for package management and running scripts
- Prefer backend StimulusReflex for server-authoritative updates
- Turbo/Haml note: ensure .html.haml extension or add initializer default_format patch
