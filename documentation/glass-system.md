# Liquid Glass System Documentation

The Liquid Glass System provides a modular, reusable way to add stunning glass effects to any component in your Rails application. The system is built around Stimulus controllers that can be easily applied to any HTML element.

## Architecture

### Base Controller

- `GlassController` - Base controller that provides core glass functionality
- Can be extended by component-specific controllers
- Handles WebGL initialization, fallbacks, and cleanup

### Component Controllers

- `NavController` - For navigation bars
- `CardController` - For card components
- `GlassButtonController` - For standalone buttons
- `SidebarController` - For sidebars (existing, can be refactored to extend GlassController)

### Render Functions

- `renderLiquidGlassNav()` - General navigation rendering
- `renderLiquidGlassSidebarRightRounded()` - Sidebar-specific rendering
- Support for preserving original HTML during loading

### Styling System

- `_glass_mixins.scss` - Reusable SCSS mixins
- Component-specific base styles
- Responsive utilities

## Quick Start

### 1. Basic Navigation Bar

```haml
%nav{data: {
       controller: "nav",
       "enable-glass-value": true,
       "nav-items": nav_items.to_json
     }}
  .nav-contents
    -# Your native HTML navigation here
```

### 2. Glass Card

```haml
%div{data: { controller: "card", "enable-glass-value": true },
     class: "glass-component glass-card"}
  .card-contents
    %h3= title
    %p= content
```

### 3. Glass Button

```haml
%button{data: {
          controller: "glass-button",
          "button-text-value": "Click Me",
          "button-path-value": "/some-path"
        }}
  .button-contents
    %span Click Me
```

## Configuration Options

### Core Glass Values

- `enable-glass-value` (Boolean) - Enable/disable glass effect
- `glass-type-value` (String) - "rounded", "circle", or "pill"
- `border-radius-value` (Number) - Border radius in pixels
- `tint-opacity-value` (Number) - Glass tint opacity (0-1)

### Layout Values

- `component-type-value` (String) - "nav", "sidebar", "card", "button"
- `corner-rounding-value` (String) - "all", "right", "left", "top", "bottom"

### Parallax Values

- `parallax-speed-value` (Number) - Parallax speed multiplier
- `is-parallax-element-value` (Boolean) - Whether element has parallax
- `sync-with-parallax-value` (Boolean) - Sync with background parallax

### Navigation Values

- `nav-items` (JSON) - Array of navigation items with path, icon, label, svg

## Creating Custom Glass Components

### 1. Extend the Base Controller

```javascript
import GlassController from "./glass_controller.js";

export default class extends GlassController {
    static values = {
        ...GlassController.values,
        // Add your custom values
        customValue: { type: String, default: "default" },
    };

    customPostRenderSetup() {
        // Add component-specific behavior
    }

    handleNavClick(item) {
        // Override navigation behavior
    }
}
```

### 2. Create Component Styles

```scss
@use "glass_mixins";

.my-component {
    @include glass_mixins.glass-container(15px, 20px);

    .my-component-contents {
        // Style native HTML to match glass
        a,
        button {
            @include glass_mixins.native-glass-button(50px, 25px);
        }
    }
}
```

### 3. Create HAML Template

```haml
%div{data: {
       controller: "my-component",
       "enable-glass-value": true,
       # Add your configuration
     },
     class: "my-component"}
  .my-component-contents
    -# Native HTML that shows during loading
```

## Advanced Features

### Preserving Original HTML

The system automatically preserves your original HTML during loading, providing:

- ✅ No flash of empty content
- ✅ Immediate user feedback
- ✅ Graceful degradation if WebGL fails
- ✅ SEO-friendly content

### Responsive Glass Effects

Use the responsive mixins for different screen sizes:

```scss
.my-sidebar {
    @include glass_mixins.glass-responsive(
        (
            small: 40px,
            medium: 60px,
            large: 80px,
        )
    );
}
```

### Custom Click Handlers

Override navigation behavior for custom interactions:

```javascript
handleNavClick(item) {
  // Custom behavior
  this.element.dispatchEvent(new CustomEvent('my-component:click', {
    detail: { item },
    bubbles: true
  }))
}
```

## Best Practices

### 1. Always Provide Native HTML

```haml
%nav{data: { controller: "nav" }}
  .nav-contents
    -# This shows immediately, gets enhanced with glass
    = link_to "Home", root_path
```

### 2. Use Appropriate Component Types

- `nav` - For navigation bars
- `sidebar` - For side navigation
- `card` - For content cards
- `button` - For standalone buttons

### 3. Configure for Your Use Case

```haml
-# High-performance sidebar
%nav{data: {
       controller: "nav",
       "tint-opacity-value": 0.08,
       "background-parallax-speed-value": 0
     }}

-# Subtle card effect
%div{data: {
       controller: "card",
       "tint-opacity-value": 0.05,
       "border-radius-value": 10
     }}
```

### 4. Handle Loading States

The system automatically handles loading states, but you can customize:

```scss
.my-component-contents {
    // This shows during loading
    opacity: 1;
    transition: opacity 300ms ease;

    // Hidden after glass loads
    &.glass-loaded {
        opacity: 0;
    }
}
```

## Browser Support

- ✅ **Modern browsers** - Full WebGL glass effects
- ✅ **Older browsers** - CSS fallback with backdrop-filter
- ✅ **No JavaScript** - Native HTML remains functional

## Performance Tips

1. **Limit concurrent glass effects** - Too many can impact performance
2. **Use appropriate tint opacity** - Lower values perform better
3. **Disable parallax if not needed** - Set `background-parallax-speed-value="0"`
4. **Consider mobile** - Glass effects are more expensive on mobile devices

## Troubleshooting

### Glass effect not showing

1. Check WebGL support: Open browser dev tools → Console
2. Verify nav-items JSON is valid
3. Ensure original HTML is present for fallback

### Performance issues

1. Reduce tint opacity
2. Disable parallax effects
3. Limit number of glass components on page

### Layout issues

1. Ensure parent containers have proper positioning
2. Check z-index conflicts
3. Verify border-radius values

## Migration Guide

### From Old Sidebar Controller

```haml
-# Old way
%nav{data: { controller: "sidebar" }}

-# New way
%nav{data: {
       controller: "nav",
       "component-type-value": "sidebar",
       "corner-rounding-value": "right"
     }}
```

The new system is backward compatible, but provides more flexibility and reusability across different component types.
