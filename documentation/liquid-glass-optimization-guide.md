# Liquid Glass Optimisation Guide

Goal

- Sustain 20–50+ concurrent glass effects at ~60 fps in UI-heavy screens.

1. Advanced Render Manager + LOD

- Viewport culling via Intersection Observer; render visible only.
- Level of Detail based on instance count and distance to viewport centre.
- Batch rendering to smooth frame pacing.
- Performance modes: auto, quality, performance.
- Tunables: per-level maxInstances, tintOpacity multipliers.
- Impact: supports 20–50+ instances; 60–80% less render work from culling.

1. Scalable WebGL Context Management

- Up to 16 concurrent contexts.
- LRU context reuse and proper state clearing.
- Shared resource pools (textures, canvases) to cut memory.
- High-performance flags for many concurrent effects.
- Impact: ~4× context capacity; 40–50% memory reduction.

1. Debounced Configuration Updates

- 300 ms debounce and requestAnimationFrame batching.
- Prevents redundant component re-creation during rapid changes.
- Impact: smoother animations, fewer main-thread stalls.

1. Container-Level Optimisations

- Centralised render loop integration.
- Optimised scroll handler registration.
- Resize debounce increased (150 ms).
- Improved destroy-time cleanup.
- Page snapshot caching with 2 s debounce.
- Impact: lower event overhead; fewer expensive captures.

1. Monitoring, Caching, and Auto-optimisation

- Validation result caching (5 s).
- Frame-time and instance-count monitoring.
- Instance caching to avoid repeated work.
- Auto-optimisation of existing components on load.
- Impact: faster validation; proactive performance detection.

Operational Guidance

- Use auto mode by default; switch to performance during heavy animations/low-end devices; quality for demos.
- Mark critical components as high priority; allow LOD for decorative/background elements.
- Tune qualityLevels (maxInstances, tintOpacity multipliers) per device profile.
- Batch updates instead of per-component mutations.
- Monitor with performance stats; disable debug in production.

Scalability Delta

- Before: 4–8 instances, fixed quality, per-component loops, basic WebGL.
- After: 20–50+ instances, viewport culling, 3-level LOD, batched rendering, LRU contexts, shared pools.

Troubleshooting (Quick Checks)

- Low FPS: inspect stats, reduce concurrency, lower tint opacity, confirm adaptive framerate.
- Memory: check context count, ensure destroy cleanup, watch for leaks.
- CPU: reduce scroll sensitivity; increase debounces where safe.

Future Opportunities

- Web Workers, OffscreenCanvas, shared WebGL textures, progressive enhancement, dynamic quality via live metrics.

Migration Notes

- Backward compatible. Import performance utilities, use batch update APIs, enable monitoring in development, follow the above best practices.
