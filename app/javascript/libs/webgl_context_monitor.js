// WebGL Context Monitor - Emergency management for context overloading
import { optimizedWebGLContextManager } from "./optimized_webgl_manager.js";
import { Container } from "./container.js";
import { glassRenderManager } from "./glass_render_manager.js";

class WebGLContextMonitor {
    constructor() {
        this.isMonitoring = false;
        this.criticalThreshold = 10; // Critical context count
        this.warningThreshold = 8; // Warning context count
        this.checkInterval = 2000; // Check every 2 seconds
        this.emergencyCleanupActive = false;

        // Performance tracking
        this.contextCreationRate = 0;
        this.recentCreations = [];
        this.maxCreationRate = 3; // Max contexts per second

        // Emergency measures
        this.emergencyPauseActive = false;
        this.emergencyPauseDuration = 5000; // 5 seconds
    }

    startMonitoring() {
        if (this.isMonitoring) return;

        this.isMonitoring = true;
        console.log("[WebGLMonitor] Starting context monitoring...");

        this.monitorInterval = setInterval(() => {
            this.checkContextHealth();
        }, this.checkInterval);
    }

    stopMonitoring() {
        if (this.monitorInterval) {
            clearInterval(this.monitorInterval);
            this.monitorInterval = undefined;
        }
        this.isMonitoring = false;
    }

    checkContextHealth() {
        const stats = optimizedWebGLContextManager.getStats();
        let containerStats;
        try {
            containerStats = Container.getStats();
        } catch {
            // Container might not be loaded yet
            containerStats = { activeInstances: 0, maxInstances: 12 };
        }

        // Calculate creation rate
        const now = Date.now();
        this.recentCreations = this.recentCreations.filter(
            (time) => now - time < 1000,
        );
        this.contextCreationRate = this.recentCreations.length;

        console.log(
            `[WebGLMonitor] Health Check - Contexts: ${stats.activeContexts}/${stats.maxContexts}, Containers: ${containerStats.activeInstances}/${containerStats.maxInstances}, Rate: ${this.contextCreationRate}/s`,
        );

        // Critical situation - immediate action required
        if (stats.activeContexts >= this.criticalThreshold) {
            this.handleCriticalSituation(stats, containerStats);
        }
        // Warning situation - preventive measures
        else if (stats.activeContexts >= this.warningThreshold) {
            this.handleWarningSituation(stats, containerStats);
        }

        // Check creation rate
        if (this.contextCreationRate > this.maxCreationRate) {
            this.handleHighCreationRate();
        }
    }

    handleCriticalSituation(stats) {
        if (this.emergencyCleanupActive) return;

        console.error(
            `[WebGLMonitor] CRITICAL: ${stats.activeContexts} active contexts! Emergency measures activated.`,
        );
        this.emergencyCleanupActive = true;

        // Emergency cleanup sequence
        this.emergencyCleanup().then(() => {
            this.emergencyCleanupActive = false;
            console.log("[WebGLMonitor] Emergency cleanup completed");
        });
    }

    async emergencyCleanup() {
        // Step 1: Force aggressive cleanup
        optimizedWebGLContextManager.aggressiveCleanup();

        // Step 2: Temporarily pause new container creation
        this.activateEmergencyPause();

        // Step 3: Force background instances to release contexts
        const backgroundInstances = [...Container.backgroundInstances];
        const toRelease = backgroundInstances.slice(
            0,
            Math.ceil(backgroundInstances.length * 0.5),
        );

        for (const instance of toRelease) {
            try {
                if (instance.element && !instance.isActivelyRendering) {
                    console.log(
                        "[WebGLMonitor] Emergency: Releasing background context",
                    );
                    optimizedWebGLContextManager.releaseContext(
                        instance.element,
                    );
                }
            } catch (error) {
                console.warn(
                    "[WebGLMonitor] Error releasing background context:",
                    error,
                );
            }
        }

        // Step 4: Wait and reassess
        await new Promise((resolve) => setTimeout(resolve, 1000));

        // Step 5: If still critical, force release more contexts
        const newStats = optimizedWebGLContextManager.getStats();
        if (newStats.activeContexts >= this.criticalThreshold) {
            console.error(
                "[WebGLMonitor] Still critical after cleanup, forcing more releases",
            );
            optimizedWebGLContextManager.forceReleaseOldestContexts(3);
        }
    }

    handleWarningSituation(stats) {
        console.warn(
            `[WebGLMonitor] WARNING: ${stats.activeContexts} active contexts approaching limit`,
        );

        // Preventive measures
        optimizedWebGLContextManager.aggressiveCleanup();

        // Reduce quality levels temporarily
        if (globalThis.glassRenderManager) {
            const currentQuality = glassRenderManager.currentQuality;
            if (currentQuality === "high") {
                glassRenderManager.adjustQualityLevel("medium");
                setTimeout(() => {
                    if (
                        optimizedWebGLContextManager.getStats().activeContexts <
                        this.warningThreshold
                    ) {
                        glassRenderManager.adjustQualityLevel("high");
                    }
                }, 10_000);
            }
        }
    }

    handleHighCreationRate() {
        if (this.emergencyPauseActive) return;

        console.warn(
            `[WebGLMonitor] High context creation rate: ${this.contextCreationRate}/s, activating emergency pause`,
        );
        this.activateEmergencyPause();
    }

    activateEmergencyPause() {
        if (this.emergencyPauseActive) return;

        this.emergencyPauseActive = true;

        // Temporarily increase container creation queue processing delay
        const originalProcessing = Container.processCreationQueue;
        Container.processCreationQueue = () => {
            if (this.emergencyPauseActive) {
                console.log("[WebGLMonitor] Creation paused due to emergency");
            } else {
                originalProcessing.call(Container);
            }
        };

        setTimeout(() => {
            this.emergencyPauseActive = false;
            Container.processCreationQueue = originalProcessing;
            console.log("[WebGLMonitor] Emergency pause lifted");
        }, this.emergencyPauseDuration);
    }

    recordContextCreation() {
        this.recentCreations.push(Date.now());
    }

    getMonitoringStats() {
        return {
            isMonitoring: this.isMonitoring,
            contextCreationRate: this.contextCreationRate,
            emergencyCleanupActive: this.emergencyCleanupActive,
            emergencyPauseActive: this.emergencyPauseActive,
            criticalThreshold: this.criticalThreshold,
            warningThreshold: this.warningThreshold,
        };
    }

    destroy() {
        this.stopMonitoring();
    }
}

// Global monitor instance
export const webglContextMonitor = new WebGLContextMonitor();

// Auto-start monitoring with better error handling
if (typeof globalThis !== "undefined") {
    // Wait for modules to be loaded
    setTimeout(() => {
        try {
            webglContextMonitor.startMonitoring();
        } catch (error) {
            console.warn("[WebGLMonitor] Failed to start monitoring:", error);
            // Retry after a delay
            setTimeout(() => {
                try {
                    webglContextMonitor.startMonitoring();
                } catch (retryError) {
                    console.error(
                        "[WebGLMonitor] Failed to start monitoring after retry:",
                        retryError,
                    );
                }
            }, 2000);
        }
    }, 1000);
}
