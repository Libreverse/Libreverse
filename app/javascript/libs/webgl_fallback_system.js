// Global WebGL fallback system
class WebGLFallbackSystem {
    constructor() {
        this.fallbackElements = new Set();
        this.isGlobalFallbackActive = false;
        this.retryAttempts = 0;
        this.maxRetryAttempts = 3;

        this.setupEventListeners();
    }

    setupEventListeners() {
        // Listen for WebGL context limit events
        window.addEventListener("webgl:contextLimitReached", (event) => {
            console.warn(
                "[WebGLFallback] Context limit reached, activating global fallback mode",
            );
            this.activateGlobalFallback(event.detail);
        });

        // Listen for individual component fallback events
        document.addEventListener("glass:fallbackActivated", (event) => {
            this.registerFallbackElement(event.detail.element);
        });

        // Listen for page visibility changes to retry when tab becomes active
        document.addEventListener("visibilitychange", () => {
            if (!document.hidden && this.isGlobalFallbackActive) {
                this.scheduleRetry();
            }
        });
    }

    activateGlobalFallback(details) {
        this.isGlobalFallbackActive = true;

        // Add global fallback indicator
        document.body.classList.add("webgl-global-fallback");

        // Show global notification
        this.showGlobalFallbackNotification(details);

        // Schedule automatic retry
        this.scheduleRetry();
    }

    registerFallbackElement(element) {
        if (element) {
            this.fallbackElements.add(element);
            element.classList.add("glass-fallback");
        }
    }

    showGlobalFallbackNotification(details) {
        // Only show if not already shown
        if (document.querySelector(".webgl-fallback-notification")) return;

        const notification = document.createElement("div");
        notification.className = "webgl-fallback-notification";
        notification.innerHTML = `
      <div class="fallback-notification-content">
        <span class="fallback-icon">⚠️</span>
        <div class="fallback-text">
          <strong>Glass effects temporarily disabled</strong><br>
          <small>Using ${details.activeContexts}/${details.maxContexts} WebGL contexts. Fallback mode active.</small>
        </div>
        <button class="fallback-retry-btn" onclick="webglFallbackSystem.retryAll()">Retry</button>
        <button class="fallback-close-btn" onclick="this.parentElement.parentElement.remove()">×</button>
      </div>
    `;

        notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: rgba(255, 165, 0, 0.95);
      color: white;
      padding: 16px;
      border-radius: 8px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      z-index: 10000;
      max-width: 350px;
      animation: slideInRight 0.3s ease;
    `;

        const style = document.createElement("style");
        style.textContent = `
      @keyframes slideInRight {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
      }
      .fallback-notification-content {
        display: flex;
        align-items: center;
        gap: 12px;
      }
      .fallback-icon {
        font-size: 24px;
      }
      .fallback-text {
        flex: 1;
        font-size: 14px;
      }
      .fallback-retry-btn, .fallback-close-btn {
        background: rgba(255, 255, 255, 0.2);
        border: none;
        color: white;
        padding: 8px 12px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 12px;
        transition: background 0.2s;
      }
      .fallback-retry-btn:hover, .fallback-close-btn:hover {
        background: rgba(255, 255, 255, 0.3);
      }
      .fallback-close-btn {
        padding: 8px 10px;
        font-weight: bold;
      }
    `;

        document.head.appendChild(style);
        document.body.appendChild(notification);

        // Auto-hide after 10 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 10000);
    }

    scheduleRetry() {
        if (this.retryAttempts >= this.maxRetryAttempts) {
            console.log(
                "[WebGLFallback] Max retry attempts reached, staying in fallback mode",
            );
            return;
        }

        const delay = Math.min(5000 * Math.pow(2, this.retryAttempts), 30000); // Exponential backoff, max 30s

        setTimeout(() => {
            this.retryAll();
        }, delay);
    }

    async retryAll() {
        if (!this.isGlobalFallbackActive && this.fallbackElements.size === 0)
            return;

        this.retryAttempts++;
        console.log(
            `[WebGLFallback] Retry attempt ${this.retryAttempts}/${this.maxRetryAttempts}`,
        );

        // Force cleanup of WebGL contexts
        if (window.optimizedWebGLContextManager) {
            window.optimizedWebGLContextManager.aggressiveCleanup();
        }

        // Wait for cleanup to complete
        await new Promise((resolve) => setTimeout(resolve, 1000));

        // Check if we have available contexts now
        const stats = window.optimizedWebGLContextManager?.getStats();
        if (!stats || stats.activeContexts >= stats.maxContexts * 0.8) {
            console.log(
                "[WebGLFallback] Still at context limit after cleanup, scheduling next retry",
            );
            this.scheduleRetry();
            return;
        }

        // Try to retry glass effects on fallback elements
        let successCount = 0;
        for (const element of this.fallbackElements) {
            try {
                // Trigger retry on glass controllers
                const glassController = element._stimulus?.controller;
                if (
                    glassController &&
                    typeof glassController.retryGlassEffect === "function"
                ) {
                    glassController.retryGlassEffect();
                    successCount++;
                }
            } catch (error) {
                console.warn(
                    "[WebGLFallback] Error retrying glass effect:",
                    error,
                );
            }
        }

        if (successCount > 0) {
            console.log(
                `[WebGLFallback] Successfully retried ${successCount} glass effects`,
            );
            this.partialRecovery();
        } else {
            console.log(
                "[WebGLFallback] No glass effects could be retried, scheduling next attempt",
            );
            this.scheduleRetry();
        }
    }

    partialRecovery() {
        // Remove global fallback state if some elements recovered
        document.body.classList.remove("webgl-global-fallback");
        this.isGlobalFallbackActive = false;

        // Remove successful elements from fallback set
        const elementsToRemove = [];
        for (const element of this.fallbackElements) {
            if (element.hasAttribute("data-glass-active")) {
                elementsToRemove.push(element);
            }
        }

        elementsToRemove.forEach((element) => {
            this.fallbackElements.delete(element);
            element.classList.remove("glass-fallback");
        });

        // Reset retry counter on successful recovery
        if (this.fallbackElements.size === 0) {
            this.retryAttempts = 0;
            console.log(
                "[WebGLFallback] Full recovery achieved, fallback system reset",
            );
        }
    }

    forceDisableFallback() {
        this.isGlobalFallbackActive = false;
        document.body.classList.remove("webgl-global-fallback");

        // Remove fallback from all elements
        this.fallbackElements.forEach((element) => {
            element.classList.remove("glass-fallback");
        });
        this.fallbackElements.clear();

        // Remove notification
        const notification = document.querySelector(
            ".webgl-fallback-notification",
        );
        if (notification) notification.remove();

        console.log("[WebGLFallback] Fallback system forcibly disabled");
    }

    getStatus() {
        return {
            globalFallbackActive: this.isGlobalFallbackActive,
            fallbackElementsCount: this.fallbackElements.size,
            retryAttempts: this.retryAttempts,
            maxRetryAttempts: this.maxRetryAttempts,
        };
    }
}

// Create global instance
window.webglFallbackSystem = new WebGLFallbackSystem();

// Export for module usage
export { WebGLFallbackSystem };
export default window.webglFallbackSystem;
