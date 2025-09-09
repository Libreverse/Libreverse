# Glass CSS System (CSS-only)

Production-ready frosted glass effects using modern CSS. No WebGL, no html2canvas.

## Features

- Utility classes: `.glass`, `.glass-sm`, `.glass-md`, `.glass-lg`
- Component bases: `.glass-sidebar-base`, `.glass-drawer-base`, `.glass-card-base`, `.glass-nav-base`, `.glass-button`
- Tunable via CSS custom properties: `--glass-*`
- Responsive and accessible fallbacks
- Optional Stimulus `glass` controller to toggle classes dynamically

## Quick start

Add the `glass` class to any element and adjust CSS variables as needed, or use component base classes for common layouts.

Example:

```haml
.glass.glass-md
    %h3 Title
    %p Content inside a frosted card
```

Using the Stimulus controller:

```html
<div
    data-controller="glass"
    data-glass-component-type-value="sidebar"
    data-glass-border-radius-value="16"
    data-glass-tint-opacity-value="0.12"
></div>
```

## Files

```text
libs/
├── simplified_glass.js  # CSS-only helpers
├── foundation.js        # Foundation integration utilities
└── button.js            # Optional button helpers (CSS-based)
```

## Browser support

Modern evergreen browsers. Fallbacks provided for `backdrop-filter` via `_fallbacks.scss`.

## License

MIT
