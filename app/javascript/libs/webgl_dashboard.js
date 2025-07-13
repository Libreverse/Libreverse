// WebGL Context Dashboard
import { optimizedWebGLContextManager } from "./optimized_webgl_manager.js";

class WebGLDashboard {
    constructor() {
        this.isVisible = false;
        this.updateInterval = null;
        this.dashboard = null;
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
            this.dashboard = null;
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
        const closeBtn = document.createElement("button");
        closeBtn.innerHTML = "×";
        closeBtn.style.cssText = `
      position: absolute;
      top: 5px;
      right: 10px;
      background: none;
      border: none;
      color: white;
      font-size: 18px;
      cursor: pointer;
    `;
        closeBtn.onclick = () => this.hide();
        this.dashboard.appendChild(closeBtn);

        // Title
        const title = document.createElement("h3");
        title.innerHTML = "WebGL Context Monitor";
        title.style.cssText = "margin: 0 0 10px 0; color: #00ff88;";
        this.dashboard.appendChild(title);

        // Stats container
        this.statsContainer = document.createElement("div");
        this.dashboard.appendChild(this.statsContainer);

        document.body.appendChild(this.dashboard);
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
            this.updateInterval = null;
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
              Monitor Status: ${monitorStats.emergencyCleanupActive ? "🚨 EMERGENCY" : monitorStats.emergencyPauseActive ? "⏸️ PAUSED" : "✅ NORMAL"}
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

        const cleanupBtn = document.createElement("button");
        cleanupBtn.innerHTML = "Force Cleanup";
        cleanupBtn.style.cssText = `
      background: #ff4444;
      color: white;
      border: none;
      padding: 5px 10px;
      border-radius: 4px;
      cursor: pointer;
      margin-right: 10px;
      font-size: 10px;
    `;
        cleanupBtn.onclick = () => {
            optimizedWebGLContextManager.aggressiveCleanup();
            console.log("[Dashboard] Force cleanup triggered");
        };

        const releaseBtn = document.createElement("button");
        releaseBtn.innerHTML = "Release 3 Oldest";
        releaseBtn.style.cssText = cleanupBtn.style.cssText;
        releaseBtn.onclick = () => {
            optimizedWebGLContextManager.forceReleaseOldestContexts(3);
            console.log("[Dashboard] Force release triggered");
        };

        actionsDiv.appendChild(cleanupBtn);
        actionsDiv.appendChild(releaseBtn);
        this.statsContainer.appendChild(actionsDiv);
    }
}

// Global dashboard instance
window.webglDashboard = new WebGLDashboard();

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
document.addEventListener("keydown", (e) => {
    if (e.ctrlKey && e.shiftKey && e.key === "W") {
        e.preventDefault();
        window.webglDashboard.toggle();
    }
});

console.log(
    "%cPress Ctrl+Shift+W to toggle dashboard",
    "color: #ffaa00; font-weight: bold;",
);
