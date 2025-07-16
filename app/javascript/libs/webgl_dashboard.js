// WebGL Context Dashboard
import { optimizedWebGLContextManager } from "./optimized_webgl_manager.js";
import { Container } from "./container.js";
import { glassRenderManager } from "./glass_render_manager.js";

class WebGLDashboard {
    constructor() {
        this.isVisible = false;
        this.updateInterval = undefined;
        this.dashboard = undefined;
    }

    show() {
        if (this.isVisible) return;

        this.createDashboard();
        this.isVisible = true;
        this.startUpdating();
    }

    hide() {
        if (!this.isVisible) return;

        if (this.dashboard) {
            this.dashboard.remove();
            this.dashboard = undefined;
        }
        this.stopUpdating();
        this.isVisible = false;
    }

    toggle() {
        if (this.isVisible) {
            this.hide();
        } else {
            this.show();
        }
    }

    createDashboard() {
        this.dashboard = document.createElement("div");
        this.dashboard.id = "webgl-dashboard";
        this.dashboard.style.cssText = `
      position: fixed;
      top: 10px;
      right: 10px;
      width: 300px;
      background: rgba(0, 0, 0, 0.9);
      color: white;
      padding: 15px;
      border-radius: 8px;
      font-family: 'Monaco', 'Menlo', monospace;
      font-size: 12px;
      z-index: 10000;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      backdrop-filter: blur(10px);
    `;

        // Close button
        const closeButton = document.createElement("button");
        closeButton.innerHTML = "×";
        closeButton.style.cssText = `
      position: absolute;
      top: 5px;
      right: 10px;
      background: none;
      border: none;
      color: white;
      font-size: 18px;
      cursor: pointer;
    `;
        closeButton.addEventListener("click", () => this.hide());
        this.dashboard.append(closeButton);

        // Title
        const title = document.createElement("h3");
        title.innerHTML = "WebGL Context Monitor";
        title.style.cssText = "margin: 0 0 10px 0; color: #00ff88;";
        this.dashboard.append(title);

        // Stats container
        this.statsContainer = document.createElement("div");
        this.dashboard.append(this.statsContainer);

        document.body.append(this.dashboard);
    }

    startUpdating() {
        this.updateInterval = setInterval(() => {
            this.updateStats();
        }, 1000);
        this.updateStats();
    }

    stopUpdating() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = undefined;
        }
    }

    updateStats() {
        if (!this.statsContainer) return;

        try {
            const stats = Container.getStats();
            const webglStats = stats.webglStats;
            const monitorStats = stats.monitoringStats;

            const contextUtilization = (
                (webglStats.activeContexts / webglStats.maxContexts) *
                100
            ).toFixed(1);
            const containerUtilization = (
                (stats.activeInstances / stats.maxInstances) *
                100
            ).toFixed(1);

            // Color coding for status
            const getStatusColor = (percentage) => {
                if (percentage < 60) return "#00ff88"; // Green
                if (percentage < 80) return "#ffaa00"; // Orange
                return "#ff4444"; // Red
            };

            const contextColor = getStatusColor(contextUtilization);
            const containerColor = getStatusColor(containerUtilization);

            this.statsContainer.innerHTML = `
        <div style="margin-bottom: 15px;">
          <div style="color: ${contextColor}; font-weight: bold;">
            WebGL Contexts: ${webglStats.activeContexts}/${webglStats.maxContexts} (${contextUtilization}%)
          </div>
          <div style="font-size: 10px; color: #888;">
            Pool: ${webglStats.pooledContexts} | Created: ${webglStats.totalCreated} | Lost: ${webglStats.totalLost}
          </div>
        </div>

        <div style="margin-bottom: 15px;">
          <div style="color: ${containerColor}; font-weight: bold;">
            Containers: ${stats.activeInstances}/${stats.maxInstances} (${containerUtilization}%)
          </div>
          <div style="font-size: 10px; color: #888;">
            Rendering: ${stats.activeRenderingInstances}/${stats.maxActiveRendering} | Background: ${stats.backgroundInstances} | Queued: ${stats.queuedCreations}
          </div>
        </div>

        ${
            monitorStats
                ? `
          <div style="margin-bottom: 15px;">
            <div style="color: ${monitorStats.emergencyCleanupActive || monitorStats.emergencyPauseActive ? "#ff4444" : "#00ff88"};">
              Monitor Status: ${monitorStats.emergencyCleanupActive ? "🚨 EMERGENCY" : (monitorStats.emergencyPauseActive ? "⏸️ PAUSED" : "✅ NORMAL")}
            </div>
            <div style="font-size: 10px; color: #888;">
              Creation Rate: ${monitorStats.contextCreationRate}/s | Thresholds: ${monitorStats.warningThreshold}/${monitorStats.criticalThreshold}
            </div>
          </div>
        `
                : ""
        }

        <div style="margin-bottom: 10px;">
          <div style="color: #88aaff;">Glass Render Manager:</div>
          <div style="font-size: 10px; color: #888;">
            Quality: ${glassRenderManager?.currentQuality || "N/A"} | 
            Instances: ${glassRenderManager?.instances?.size || 0} | 
            Visible: ${glassRenderManager?.visibleInstances?.size || 0}
          </div>
        </div>

        <div style="font-size: 10px; color: #666; margin-top: 10px;">
          Last Update: ${new Date().toLocaleTimeString()}
        </div>
      `;

            // Add emergency actions if needed
            if (
                monitorStats &&
                (monitorStats.emergencyCleanupActive ||
                    webglStats.activeContexts >= 8)
            ) {
                this.addEmergencyActions();
            }
        } catch (error) {
            this.statsContainer.innerHTML = `<div style="color: #ff4444;">Error updating stats: ${error.message}</div>`;
        }
    }

    addEmergencyActions() {
        const actionsDiv = document.createElement("div");
        actionsDiv.style.cssText =
            "margin-top: 10px; padding-top: 10px; border-top: 1px solid #333;";

        const cleanupButton = document.createElement("button");
        cleanupButton.innerHTML = "Force Cleanup";
        cleanupButton.style.cssText = `
      background: #ff4444;
      color: white;
      border: none;
      padding: 5px 10px;
      border-radius: 4px;
      cursor: pointer;
      margin-right: 10px;
      font-size: 10px;
    `;
        cleanupButton.addEventListener("click", () => {
            optimizedWebGLContextManager.aggressiveCleanup();
            console.log("[Dashboard] Force cleanup triggered");
        });

        const releaseButton = document.createElement("button");
        releaseButton.innerHTML = "Release 3 Oldest";
        releaseButton.style.cssText = cleanupButton.style.cssText;
        releaseButton.addEventListener("click", () => {
            optimizedWebGLContextManager.forceReleaseOldestContexts(3);
            console.log("[Dashboard] Force release triggered");
        });

        actionsDiv.append(cleanupButton);
        actionsDiv.append(releaseButton);
        this.statsContainer.append(actionsDiv);
    }
}

// Global dashboard instance
globalThis.webglDashboard = new WebGLDashboard();

// Console shortcuts
console.log(
    "%c[WebGL Dashboard] Available commands:",
    "color: #00ff88; font-weight: bold;",
);
console.log(
    "%cwebglDashboard.show() - Show monitoring dashboard",
    "color: #88aaff;",
);
console.log("%cwebglDashboard.hide() - Hide dashboard", "color: #88aaff;");
console.log("%cwebglDashboard.toggle() - Toggle dashboard", "color: #88aaff;");
console.log("%cContainer.getStats() - Get detailed stats", "color: #88aaff;");

// Keyboard shortcut
document.addEventListener("keydown", (event) => {
    if (event.ctrlKey && event.shiftKey && event.key === "W") {
        event.preventDefault();
        globalThis.webglDashboard.toggle();
    }
});

console.log(
    "%cPress Ctrl+Shift+W to toggle dashboard",
    "color: #ffaa00; font-weight: bold;",
);
