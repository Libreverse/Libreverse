// Critical Element Fallback Activator
// Immediately activates fallbacks for critical navigation elements when glass fails

class CriticalElementFallback {
    constructor() {
        this.criticalSelectors = [
            '[data-controller*="sidebar"]',
            '[data-controller*="glass-drawer"]',
            "nav",
            ".nav-item",
            ".sidebar-nav",
            ".drawer-container",
        ];

        this.activateFallbacksImmediately();
        this.setupMutationObserver();
    }

    activateFallbacksImmediately() {
        // Run immediately and also after DOM ready
        this.scanAndActivateFallbacks();

        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", () => {
                this.scanAndActivateFallbacks();
            });
        }
    }

    scanAndActivateFallbacks() {
        for (const selector of this.criticalSelectors) {
            const elements = document.querySelectorAll(selector);
            for (const element of elements) {
                this.ensureElementVisibility(element);
            }
        }
    }

    ensureElementVisibility(element) {
        // Check if element is invisible or has no glass effect
        const hasGlassActive = Object.hasOwn(element.dataset, "glassActive");
        const isVisible = this.isElementVisible(element);

        if (!hasGlassActive && !isVisible) {
            console.log(
                "[CriticalFallback] Activating emergency fallback for:",
                element,
            );
            this.activateEmergencyFallback(element);
        }
    }

    isElementVisible(element) {
        const style = globalThis.getComputedStyle(element);
        const rect = element.getBoundingClientRect();

        return (
            style.opacity !== "0" &&
            style.visibility !== "hidden" &&
            style.display !== "none" &&
            rect.width > 0 &&
            rect.height > 0
        );
    }

    activateEmergencyFallback(element) {
        // Add fallback class
        element.classList.add("glass-fallback");

        // Ensure visibility
        element.style.opacity = "1";
        element.style.visibility = "visible";
        element.style.display = element.style.display || "block";

        // Apply emergency styling based on element type
        if (
            element.matches('[data-controller*="sidebar"], nav, .sidebar-nav')
        ) {
            this.applySidebarEmergencyStyle(element);
        } else if (
            element.matches('[data-controller*="drawer"], .drawer-container')
        ) {
            this.applyDrawerEmergencyStyle(element);
        }

        // Dispatch fallback event
        const event = new CustomEvent("glass:fallbackActivated", {
            detail: { element, reason: "critical-element-invisible" },
        });
        element.dispatchEvent(event);
    }

    applySidebarEmergencyStyle(element) {
        Object.assign(element.style, {
            background:
                "linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%)",
            borderRadius: "12px",
            padding: "16px",
            margin: "8px",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            backdropFilter: "blur(10px)",
        });

        // Style navigation items
        const navItems = element.querySelectorAll("a, button, .nav-item");
        for (const item of navItems) {
            Object.assign(item.style, {
                color: "rgba(255, 255, 255, 0.9)",
                opacity: "1",
                visibility: "visible",
                display: "block",
                padding: "8px 12px",
                borderRadius: "6px",
                transition: "all 0.2s ease",
            });
        }
    }

    applyDrawerEmergencyStyle(element) {
        Object.assign(element.style, {
            background:
                "linear-gradient(to bottom, rgba(0, 0, 0, 0.8) 0%, rgba(0, 0, 0, 0.9) 100%)",
            borderRadius: "20px 20px 0 0",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            boxShadow: "0 -4px 30px rgba(0, 0, 0, 0.3)",
        });
    }

    setupMutationObserver() {
        // Watch for new elements being added
        const observer = new MutationObserver((mutations) => {
            for (const mutation of mutations) {
                for (const node of mutation.addedNodes) {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        for (const selector of this.criticalSelectors) {
                            if (node.matches?.(selector)) {
                                setTimeout(() => {
                                    this.ensureElementVisibility(node);
                                }, 100);
                            }

                            // Check children too
                            const children = node.querySelectorAll?.(selector);
                            if (children)
                                for (const child of children) {
                                    setTimeout(() => {
                                        this.ensureElementVisibility(child);
                                    }, 100);
                                }
                        }
                    }
                }
            }
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
        });
    }
}

// Initialize immediately
if (typeof globalThis !== "undefined") {
    globalThis.criticalElementFallback = new CriticalElementFallback();
}

export default CriticalElementFallback;
