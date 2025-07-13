// Global Glass Render Manager - Optimized for high scalability with many concurrent glass effects
class GlassRenderManager {
    constructor() {
        this.instances = new Set();
        this.visibleInstances = new Set();
        this.isRunning = false;
        this.lastFrameTime = 0;
        this.targetFPS = 60;
        this.frameDuration = 1000 / this.targetFPS;
        this.scrollHandler = this.handleScroll.bind(this);
        this.resizeHandler = this.handleResize.bind(this);
        this.lastScrollY = window.scrollY;
        this.scrollVelocity = 0;
        this.isDirty = false;

        // Advanced performance tracking for many instances
        this.averageFrameTime = 16.67; // Start at 60fps
        this.frameTimeHistory = [];
        this.maxFrameHistory = 20; // Increased for better average
        this.performanceMode = "auto"; // 'auto', 'performance', 'quality'

        // Viewport-based optimization
        this.viewportObserver = null;
        this.viewportBuffer = 100; // px buffer around viewport

        // Instance batching for performance
        this.batchSize = 8; // Render instances in batches
        this.currentBatch = 0;

        // LOD (Level of Detail) system
        this.lodEnabled = true;
        this.qualityLevels = {
            high: { maxInstances: 20, tintOpacityMultiplier: 1.0 },
            medium: { maxInstances: 35, tintOpacityMultiplier: 0.8 },
            low: { maxInstances: 50, tintOpacityMultiplier: 0.6 },
        };
        this.currentQuality = "high";

        this.setupGlobalListeners();
        this.setupViewportObserver();
    }

    setupGlobalListeners() {
        // Single global scroll handler with throttling for many instances
        let scrollTicking = false;
        const throttledScrollHandler = () => {
            if (!scrollTicking) {
                requestAnimationFrame(() => {
                    this.handleScroll();
                    scrollTicking = false;
                });
                scrollTicking = true;
            }
        };

        window.addEventListener("scroll", throttledScrollHandler, {
            passive: true,
        });
        window.addEventListener("resize", this.resizeHandler, {
            passive: true,
        });

        // Locomotive Scroll integration with throttling
        if (window.locomotiveScroll) {
            if (typeof window.locomotiveScroll.on === "function") {
                window.locomotiveScroll.on("scroll", throttledScrollHandler);
            }
        }

        // Store references for cleanup
        this._throttledScrollHandler = throttledScrollHandler;
    }

    setupViewportObserver() {
        // Use Intersection Observer to track which glass effects are visible
        if (typeof IntersectionObserver !== "undefined") {
            this.viewportObserver = new IntersectionObserver(
                (entries) => {
                    entries.forEach((entry) => {
                        const instance = entry.target._glassInstance;
                        if (instance) {
                            if (entry.isIntersecting) {
                                this.visibleInstances.add(instance);
                                instance.isVisible = true;
                            } else {
                                this.visibleInstances.delete(instance);
                                instance.isVisible = false;
                            }
                        }
                    });
                },
                {
                    rootMargin: `${this.viewportBuffer}px`,
                    threshold: 0.01, // Very small threshold for early detection
                },
            );
        }
    }

    register(instance) {
        this.instances.add(instance);

        // Set up viewport tracking for this instance
        if (this.viewportObserver && instance.element) {
            instance.element._glassInstance = instance;
            this.viewportObserver.observe(instance.element);
        }

        // Auto-adjust quality based on instance count
        this.adjustQualityLevel();

        this.start();
    }

    unregister(instance) {
        this.instances.delete(instance);
        this.visibleInstances.delete(instance);

        // Stop observing this instance
        if (this.viewportObserver && instance.element) {
            this.viewportObserver.unobserve(instance.element);
            delete instance.element._glassInstance;
        }

        if (this.instances.size === 0) {
            this.stop();
        } else {
            // Re-adjust quality level
            this.adjustQualityLevel();
        }
    }

    start() {
        if (!this.isRunning) {
            this.isRunning = true;
            this.renderLoop();
        }
    }

    stop() {
        this.isRunning = false;
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
    }

    markDirty() {
        this.isDirty = true;
    }

    handleScroll() {
        const currentScrollY = window.scrollY;
        this.scrollVelocity = Math.abs(currentScrollY - this.lastScrollY);
        this.lastScrollY = currentScrollY;

        // Only mark dirty if scroll velocity is significant
        if (this.scrollVelocity > 1) {
            this.markDirty();
        }
    }

    handleResize() {
        // Debounced resize handling
        clearTimeout(this.resizeTimeout);
        this.resizeTimeout = setTimeout(() => {
            this.markDirty();
            // Force page snapshot recapture on resize
            Container.pageSnapshot = null;
        }, 200);
    }

    renderLoop() {
        if (!this.isRunning) return;

        const now = performance.now();
        const elapsed = now - this.lastFrameTime;

        // Adaptive frame rate - but prioritize visible instances
        const shouldRender = elapsed >= this.frameDuration || this.isDirty;

        if (shouldRender) {
            const frameStart = performance.now();

            // Prioritize visible instances for rendering
            const instancesToRender = this.lodEnabled
                ? Array.from(this.visibleInstances)
                : Array.from(this.instances);

            let renderedCount = 0;

            // Batch rendering for better performance with many instances
            const batchSize = Math.min(
                this.batchSize,
                instancesToRender.length,
            );
            const startIndex = this.currentBatch * batchSize;
            const endIndex = Math.min(
                startIndex + batchSize,
                instancesToRender.length,
            );

            // Render current batch
            for (let i = startIndex; i < endIndex; i++) {
                const instance = instancesToRender[i];
                if (instance && (instance.needsRender || this.isDirty)) {
                    try {
                        // Apply LOD optimizations
                        this.applyLODOptimizations(instance);
                        instance.renderFrame();
                        instance.needsRender = false;
                        renderedCount++;
                    } catch (error) {
                        console.warn(
                            "[GlassRenderManager] Error rendering instance:",
                            error,
                        );
                    }
                }
            }

            // Move to next batch
            this.currentBatch =
                (this.currentBatch + 1) %
                Math.ceil(instancesToRender.length / batchSize);

            // Also render any non-visible instances that urgently need updates (less frequently)
            if (this.lodEnabled && this.currentBatch === 0) {
                const nonVisibleInstances = Array.from(this.instances).filter(
                    (i) => !i.isVisible,
                );
                const urgentNonVisible = nonVisibleInstances.filter(
                    (i) => i.needsRender && i.priority === "high",
                );

                for (const instance of urgentNonVisible.slice(0, 2)) {
                    // Limit to 2 per frame
                    try {
                        this.applyLODOptimizations(instance);
                        instance.renderFrame();
                        instance.needsRender = false;
                        renderedCount++;
                    } catch (error) {
                        console.warn(
                            "[GlassRenderManager] Error rendering non-visible instance:",
                            error,
                        );
                    }
                }
            }

            const frameTime = performance.now() - frameStart;
            this.updateFrameRate(frameTime);

            this.lastFrameTime = now;
            this.isDirty = false;

            // Continue rendering if we have instances or if we're batching
            if (this.instances.size > 0) {
                this.animationId = requestAnimationFrame(() =>
                    this.renderLoop(),
                );
            }
        } else {
            this.animationId = requestAnimationFrame(() => this.renderLoop());
        }
    }

    updateFrameRate(frameTime) {
        this.frameTimeHistory.push(frameTime);
        if (this.frameTimeHistory.length > this.maxFrameHistory) {
            this.frameTimeHistory.shift();
        }

        this.averageFrameTime =
            this.frameTimeHistory.reduce((a, b) => a + b, 0) /
            this.frameTimeHistory.length;

        // More aggressive adaptive FPS for many instances
        if (this.performanceMode === "auto") {
            if (this.averageFrameTime > 25) {
                // Slower than 40fps
                this.targetFPS = Math.max(20, this.targetFPS - 10);
                this.batchSize = Math.max(2, this.batchSize - 2);
            } else if (this.averageFrameTime > 20) {
                // Slower than 50fps
                this.targetFPS = Math.max(30, this.targetFPS - 5);
                this.batchSize = Math.max(4, this.batchSize - 1);
            } else if (this.averageFrameTime < 10) {
                // Faster than 100fps
                this.targetFPS = Math.min(60, this.targetFPS + 5);
                this.batchSize = Math.min(12, this.batchSize + 1);
            } else if (this.averageFrameTime < 12) {
                // Faster than 83fps
                this.targetFPS = Math.min(60, this.targetFPS + 2);
            }

            this.frameDuration = 1000 / this.targetFPS;
        }
    }

    adjustQualityLevel() {
        const instanceCount = this.instances.size;
        let newQuality = this.currentQuality;

        if (instanceCount <= this.qualityLevels.high.maxInstances) {
            newQuality = "high";
        } else if (instanceCount <= this.qualityLevels.medium.maxInstances) {
            newQuality = "medium";
        } else {
            newQuality = "low";
        }

        if (newQuality !== this.currentQuality) {
            console.log(
                `[GlassRenderManager] Adjusting quality from ${this.currentQuality} to ${newQuality} for ${instanceCount} instances`,
            );
            this.currentQuality = newQuality;

            // Apply quality changes to all instances
            this.instances.forEach((instance) => {
                this.applyLODOptimizations(instance);
            });
        }
    }

    applyLODOptimizations(instance) {
        if (!this.lodEnabled || !instance) return;

        const quality = this.qualityLevels[this.currentQuality];

        // Adjust tint opacity based on quality level
        if (instance.originalTintOpacity === undefined) {
            instance.originalTintOpacity = instance.tintOpacity || 0.12;
        }

        const adjustedOpacity =
            instance.originalTintOpacity * quality.tintOpacityMultiplier;

        // Apply optimizations if the instance supports them
        if (instance.setTintOpacity) {
            instance.setTintOpacity(adjustedOpacity);
        }

        // Distance-based optimizations
        if (instance.element && instance.isVisible !== undefined) {
            const rect = instance.element.getBoundingClientRect();
            const distanceFromCenter = Math.abs(
                rect.top + rect.height / 2 - window.innerHeight / 2,
            );
            const maxDistance = window.innerHeight / 2;
            const distanceRatio = Math.min(distanceFromCenter / maxDistance, 1);

            // Reduce quality for elements far from viewport center
            if (distanceRatio > 0.7) {
                if (instance.setRenderQuality) {
                    instance.setRenderQuality("low");
                }
            } else if (distanceRatio > 0.4) {
                if (instance.setRenderQuality) {
                    instance.setRenderQuality("medium");
                }
            } else {
                if (instance.setRenderQuality) {
                    instance.setRenderQuality("high");
                }
            }
        }
    }

    setPerformanceMode(mode) {
        this.performanceMode = mode;

        switch (mode) {
            case "performance":
                this.targetFPS = 30;
                this.batchSize = 4;
                this.lodEnabled = true;
                break;
            case "quality":
                this.targetFPS = 60;
                this.batchSize = 12;
                this.lodEnabled = false;
                break;
            case "auto":
            default:
                this.targetFPS = 60;
                this.batchSize = 8;
                this.lodEnabled = true;
                break;
        }

        this.frameDuration = 1000 / this.targetFPS;
        console.log(`[GlassRenderManager] Performance mode set to: ${mode}`);
    }

    // Method to temporarily boost performance for animations
    boostPerformance(duration = 5000) {
        const originalMode = this.performanceMode;
        this.setPerformanceMode("performance");

        setTimeout(() => {
            this.setPerformanceMode(originalMode);
        }, duration);
    }

    // Method to get current performance statistics
    getPerformanceStats() {
        return {
            totalInstances: this.instances.size,
            visibleInstances: this.visibleInstances.size,
            currentQuality: this.currentQuality,
            performanceMode: this.performanceMode,
            averageFrameTime: this.averageFrameTime.toFixed(2),
            targetFPS: this.targetFPS,
            batchSize: this.batchSize,
            lodEnabled: this.lodEnabled,
        };
    }

    destroy() {
        this.stop();

        // Clean up viewport observer
        if (this.viewportObserver) {
            this.viewportObserver.disconnect();
            this.viewportObserver = null;
        }

        // Clean up event listeners
        window.removeEventListener("scroll", this._throttledScrollHandler);
        window.removeEventListener("resize", this.resizeHandler);

        if (
            window.locomotiveScroll &&
            typeof window.locomotiveScroll.off === "function"
        ) {
            window.locomotiveScroll.off("scroll", this._throttledScrollHandler);
        }

        // Clear all instances
        this.instances.clear();
        this.visibleInstances.clear();
    }
}

// Global singleton instance
export const glassRenderManager = new GlassRenderManager();
