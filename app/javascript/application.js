import "../stylesheets/application.scss";
import "./libs/webgl_fallback_system.js"; // Add fallback system
import "./libs/critical_element_fallback.js"; // Add critical element fallback
import "./libs/glass_fallback_monitor.js"; // Enhanced glass fallback monitoring
import "./libs/hashcash.js"; // ActiveHashcash proof-of-work for bot protection
import html2canvas from "html2canvas";
import debounced from "debounced";
import "./libs/foundation.js";
import "./libs/websocket_p2p_frame.coffee";
import "what-input";
import { load } from "@fingerprintjs/botd";

// GDPR-Compliant Error Tracking Setup
import * as Sentry from "@sentry/browser";

// Initialize Sentry with GDPR-compliant configuration
Sentry.init({
    // GlitchTip DSN (public, safe to hardcode)
    dsn: "https://dff68bb3ecd94f9faa29a454704040e8@app.glitchtip.com/12078",

    environment: import.meta.env.MODE || "development",

    // Only enable in production
    enabled: import.meta.env.MODE === "production",

    // GDPR Compliance: Remove all personal data before sending
    beforeSend(event) {
        // Remove user data completely
        delete event.user;

        // Remove request data that may contain personal information
        if (event.request) {
            delete event.request.headers;
            delete event.request.cookies;
            delete event.request.data;
        }

        // Anonymize stack traces - keep only filename, remove full paths
        if (event.exception?.values) {
            for (const exception of event.exception.values) {
                if (exception.stacktrace?.frames) {
                    for (const frame of exception.stacktrace.frames) {
                        // Keep only filename, remove server paths
                        if (frame.filename) {
                            frame.filename = frame.filename.split("/").pop();
                        }
                        // Remove local variables that might contain personal data
                        delete frame.vars;
                    }
                }
            }
        }

        return event;
    },

    // Disable performance monitoring to reduce data collection
    tracesSampleRate: 0,

    // Minimal breadcrumbs collection
    maxBreadcrumbs: 5,

    // Disable console capture and other automatic data collection
    captureConsole: false,
});

const BOTD_COOKIE = "botd";
const BOTD_TTL_MIN = 60; // Cookie lifetime

(function setBotdCookie() {
    if (document.cookie.includes(`${BOTD_COOKIE}=`)) return; // already set

    // Load BotD and run detection
    load()
        .then((agent) => agent.detect())
        .then(({ bot }) => {
            const expires = new Date(
                Date.now() + BOTD_TTL_MIN * 60_000,
            ).toUTCString();
            document.cookie = [
                `${BOTD_COOKIE}=${bot ? 1 : 0}`,
                `expires=${expires}`,
                "path=/",
                "SameSite=Lax", // add 'Secure' if your site is HTTPS-only
            ].join("; ");
        })
        .catch((error) => {
            /* Detection failed – leave cookie unset so the backend can flag it */
            console.error("[BotD] detection error:", error);
        });
})();

// Add Foundation debugging in development
if (import.meta.env.MODE === "development") {
    // Simple Foundation status checker
    function checkFoundation() {
        console.group("Foundation Status Check");

        import("foundation-sites")
            .then(() => {
                console.log("✅ Foundation imported successfully");

                const offCanvasElements =
                    document.querySelectorAll("[data-off-canvas]");
                console.log(
                    `📋 Found ${offCanvasElements.length} off-canvas elements`,
                );

                if (globalThis.Stimulus) {
                    console.log("✅ Stimulus available");
                } else {
                    console.warn("⚠️ Stimulus not available");
                }

                console.groupEnd();
            })
            .catch((error) => {
                console.error("❌ Foundation import failed:", error);
                console.groupEnd();
            });
    }

    // Check Foundation status after DOM loads
    document.addEventListener("DOMContentLoaded", checkFoundation);
    document.addEventListener("turbo:load", checkFoundation);
}

// Initialize debounced library with custom options
debounced.initialize(debounced.defaultEventNames, {
    wait: 300, // Default wait time in milliseconds
    leading: false, // Don't fire immediately on first event
    trailing: true, // Fire after waiting period
});

// Register additional debounced events with different timing for forms
debounced.register(["input"], {
    wait: 800, // Longer wait for form auto-submit
    leading: false,
    trailing: true,
});

// Register resize events with shorter debounce for better UX
debounced.register(["resize"], {
    wait: 200, // Shorter wait for resize events
    leading: false,
    trailing: true,
});

// Make html2canvas globally available for liquid glass effects
globalThis.html2canvas = html2canvas;

import * as Turbo from "@hotwired/turbo";
import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);
import "./config/stimulus_reflex";
import "./controllers";
import "./config";
import "./channels";
import { start } from "@rails/activestorage";
start();

// Check for cookie clearing instructions on every HTTP response
// This handles cases where the server detects invalid sessions
function checkForCookieClearHeaders() {
    // Create a MutationObserver to watch for new HTTP responses
    // We'll intercept fetch and XMLHttpRequest to check headers

    const originalFetch = globalThis.fetch;
    globalThis.fetch = function (...fetchArguments) {
        return originalFetch.apply(this, fetchArguments).then((response) => {
            checkResponseHeaders(response);
            return response;
        });
    };

    // Also intercept XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (...openArguments) {
        this.addEventListener("readystatechange", function () {
            if (this.readyState === 4) {
                checkXHRHeaders(this);
            }
        });
        return originalOpen.apply(this, openArguments);
    };
}

function checkResponseHeaders(response) {
    const clearCookies = response.headers.get("X-Clear-Cookies");
    const reloadRequired = response.headers.get("X-Reload-Required");

    if (clearCookies === "invalid-session" && reloadRequired === "true") {
        handleInvalidSession();
    }
}

function checkXHRHeaders(xhr) {
    const clearCookies = xhr.getResponseHeader("X-Clear-Cookies");
    const reloadRequired = xhr.getResponseHeader("X-Reload-Required");

    if (clearCookies === "invalid-session" && reloadRequired === "true") {
        handleInvalidSession();
    }
}

function handleInvalidSession() {
    console.log("Invalid session detected, clearing cookies and reloading...");

    // Prevent multiple simultaneous clears
    if (sessionStorage.getItem("clearing_cookies") === "true") {
        return;
    }
    sessionStorage.setItem("clearing_cookies", "true");

    // Clear all cookies
    const cookies = document.cookie.split(";");
    for (const c of cookies) {
        document.cookie = c
            .replace(/^ +/, "")
            .replace(/=.*/, "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/");
    }

    // Reload the page
    globalThis.location.reload();
}

// Initialize the header checking
document.addEventListener("DOMContentLoaded", checkForCookieClearHeaders);
