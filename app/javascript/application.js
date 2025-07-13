import "../stylesheets/application.scss";
import "./libs/webgl_fallback_system.js"; // Add fallback system
import "./libs/critical_element_fallback.js"; // Add critical element fallback
import "./libs/glass_fallback_monitor.js"; // Enhanced glass fallback monitoring
import html2canvas from "html2canvas";
import debounced from "debounced";
import "./libs/foundation.js";
import "./libs/websocket_p2p_frame.coffee";

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
        // eslint-disable-next-line -- Need direct access to clear invalid session cookies
        document.cookie = c
            .replace(/^ +/, "")
            .replace(/=.*/, "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/");
    }

    // Reload the page
    globalThis.location.reload();
}

// Initialize the header checking
document.addEventListener("DOMContentLoaded", checkForCookieClearHeaders);
