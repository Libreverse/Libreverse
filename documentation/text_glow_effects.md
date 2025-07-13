# Text Glow Effects

This component provides reusable text glow effects extracted from the authentication and card components.

## Usage

### Using Placeholder Selectors

```scss
@use "../components/text_effects";

.my-heading {
    @extend %text-glow-primary; // Standard primary color glow
    @extend %text-glow-secondary; // Secondary color glow
    @extend %text-glow-subtle; // Subtle glow effect
    @extend %text-glow-intense; // Intense glow effect
}
```

### Using the Mixin

```scss
@use "../components/text_effects";

.custom-glow {
    @include text_effects.text-glow(
        $color: #ff0080,
        $intensity: 0.6,
        $duration: 2s
    );
}
```

## Parameters

- `$color`: The color of the glow (default: variables.$login-primary)
- `$intensity`: The opacity intensity of the glow (default: 0.5)
- `$duration`: The animation duration (default: 3s)

## Available Variants

- `%text-glow-primary`: Standard glow with primary color
- `%text-glow-secondary`: Glow with secondary color
- `%text-glow-subtle`: Lighter, slower glow effect
- `%text-glow-intense`: Stronger, faster glow effect

## Migration Notes

This component replaces the individual text-shadow and animation declarations that were previously scattered across multiple files. The animation creates a pulsing effect that alternates between lighter and stronger glow intensities.
