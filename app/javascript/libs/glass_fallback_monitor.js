/**
 * Enhanced Glass Fallback Monitor
 * Monitors WebGL health and proactively activates fallback when needed
 */

class GlassFallbackMonitor {
    constructor() {
        this.webglHealthy = true;
        this.contextLossCount = 0;
        this.maxContextLoss = 3;
        this.monitoringInterval = null;
        this.observers = new Set();

        this.init();
    }

    init() {
        // Monitor WebGL context health
        this.setupWebGLMonitoring();

        // Monitor performance
        this.setupPerformanceMonitoring();

        // Listen for visibility changes
        this.setupVisibilityMonitoring();

        // Start periodic health checks
        this.startMonitoring();
    }

    setupWebGLMonitoring() {
        // Override WebGL context creation to monitor health
        const canvas = document.createElement("canvas");
        const gl =
            canvas.getContext("webgl") ||
            canvas.getContext("experimental-webgl");

        if (!gl) {
            this.webglHealthy = false;
            return;
        }

        // Listen for context loss events
        canvas.addEventListener("webglcontextlost", (event) => {
            console.warn("[GlassFallbackMonitor] WebGL context lost");
            this.contextLossCount++;
            this.webglHealthy = false;

            if (this.contextLossCount >= this.maxContextLoss) {
                this.triggerGlobalFallback(
                    "Multiple WebGL context losses detected",
                );
            }

            event.preventDefault();
        });

        canvas.addEventListener("webglcontextrestored", (event) => {
            console.log("[GlassFallbackMonitor] WebGL context restored");
            this.webglHealthy = true;
        });
    }

    setupPerformanceMonitoring() {
        // Monitor frame rate and performance
        let frameCount = 0;
        let lastTime = performance.now();

        const checkPerformance = () => {
            frameCount++;
            const currentTime = performance.now();

            if (currentTime - lastTime >= 5000) {
                // Check every 5 seconds
                const fps = frameCount / ((currentTime - lastTime) / 1000);

                if (fps < 15) {
                    // If FPS drops below 15, consider fallback
                    console.warn(
                        "[GlassFallbackMonitor] Low FPS detected:",
                        fps,
                    );
                    this.triggerGlobalFallback("Poor performance detected");
                }

                frameCount = 0;
                lastTime = currentTime;
            }

            if (this.webglHealthy) {
                requestAnimationFrame(checkPerformance);
            }
        };

        if (this.webglHealthy) {
            requestAnimationFrame(checkPerformance);
        }
    }

    setupVisibilityMonitoring() {
        // Handle page visibility changes
        document.addEventListener("visibilitychange", () => {
            if (document.hidden) {
                // Page is hidden, pause monitoring
                this.pauseMonitoring();
            } else {
                // Page is visible again, resume monitoring
                this.resumeMonitoring();
            }
        });
    }

    startMonitoring() {
        this.monitoringInterval = setInterval(() => {
            this.checkSystemHealth();
        }, 10000); // Check every 10 seconds
    }

    pauseMonitoring() {
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
            this.monitoringInterval = null;
        }
    }

    resumeMonitoring() {
        if (!this.monitoringInterval) {
            this.startMonitoring();
        }
    }

    checkSystemHealth() {
        // Check memory usage
        if (performance.memory) {
            const memoryUsage =
                performance.memory.usedJSHeapSize /
                performance.memory.jsHeapSizeLimit;

            if (memoryUsage > 0.9) {
                console.warn(
                    "[GlassFallbackMonitor] High memory usage detected:",
                    memoryUsage,
                );
                this.triggerGlobalFallback("High memory usage detected");
            }
        }

        // Check for WebGL context availability
        const canvas = document.createElement("canvas");
        const gl =
            canvas.getContext("webgl") ||
            canvas.getContext("experimental-webgl");

        if (!gl && this.webglHealthy) {
            this.webglHealthy = false;
            this.triggerGlobalFallback("WebGL context unavailable");
        }
    }

    triggerGlobalFallback(reason) {
        console.warn(
            `[GlassFallbackMonitor] Triggering global fallback: ${reason}`,
        );

        // Find all glass components and switch them to fallback
        const glassElements = document.querySelectorAll(
            '[data-controller*="glass"]:not(.glass-fallback)',
        );

        glassElements.forEach((element) => {
            const controller = this.getControllerInstance(element);
            if (controller && typeof controller.setupFallback === "function") {
                controller.setupFallback();
            } else {
                // Manual fallback for elements without accessible controller
                this.manualFallback(element);
            }
        });

        // Notify observers
        this.notifyObservers(reason);
    }

    getControllerInstance(element) {
        // Try to get Stimulus controller instance
        if (element.stimulusController) {
            return element.stimulusController;
        }

        // Alternative method to get controller
        if (window.Stimulus && window.Stimulus.application) {
            const controllers =
                window.Stimulus.application.getControllerForElementAndIdentifier(
                    element,
                    "glass",
                );
            return controllers;
        }

        return null;
    }

    manualFallback(element) {
        // Apply manual fallback styles
        element.classList.add("glass-fallback");
        element.removeAttribute("data-glass-active");
        element.style.opacity = "1";
        element.style.visibility = "visible";

        // Hide glass containers
        const glassContainers = element.querySelectorAll(".glass-container");
        glassContainers.forEach((container) => {
            container.style.display = "none";
        });
    }

    addObserver(callback) {
        this.observers.add(callback);
    }

    removeObserver(callback) {
        this.observers.delete(callback);
    }

    notifyObservers(reason) {
        this.observers.forEach((callback) => {
            try {
                callback(reason);
            } catch (error) {
                console.error("[GlassFallbackMonitor] Observer error:", error);
            }
        });
    }

    destroy() {
        this.pauseMonitoring();
        this.observers.clear();
    }
}

// Initialize the monitor when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
    if (!window.glassFallbackMonitor) {
        window.glassFallbackMonitor = new GlassFallbackMonitor();
        console.log("[GlassFallbackMonitor] Initialized");
    }
});

// Clean up on page unload
window.addEventListener("beforeunload", () => {
    if (window.glassFallbackMonitor) {
        window.glassFallbackMonitor.destroy();
    }
});

export { GlassFallbackMonitor };
