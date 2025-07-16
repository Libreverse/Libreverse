import { Container } from "./container.js";
import { validateLiquidGlass } from "./liquid_glass.js";

/**
 * Simplified Glass Integration - Works with existing HTML structure
 * Only handles background glass effects, no button generation
 */

/**
 * Enhanced existing HTML elements with glass effects without DOM restructuring
 * @param {HTMLElement} element - The element to enhance
 * @param {Object} options - Configuration options
 */
export async function enhanceWithGlass(element, options = {}) {
    const {
        componentType = "nav",
        borderRadius = 20,
        tintOpacity = 0.12,
        cornerRounding = "all",
    } = options;

    // Validate glass can be applied
    if (!validateLiquidGlass(element)) {
        console.warn(
            "[SimplifiedGlass] WebGL validation failed, using CSS fallback",
        );
        element.classList.add("glass-fallback", `glass-${componentType}`);
        return;
    }

    try {
        // Set up glass states
        element.classList.add("glass-loading", `glass-${componentType}`);
        element.dataset.glassActive = "true";

        // Create glass container that overlays existing content
        const glassContainer = await createGlassOverlay(element, {
            borderRadius,
            tintOpacity,
            cornerRounding,
            componentType,
        });

        if (!glassContainer) {
            throw new Error("Failed to create glass container");
        }

        // Position glass container behind existing content
        glassContainer.element.style.position = "absolute";
        glassContainer.element.style.top = "0";
        glassContainer.element.style.left = "0";
        glassContainer.element.style.width = "100%";
        glassContainer.element.style.height = "100%";
        glassContainer.element.style.zIndex = "0";
        glassContainer.element.style.pointerEvents = "none";

        // NO BORDER RADIUS MANIPULATION - let CSS handle everything
        // Remove any inline border radius that might interfere with CSS
        glassContainer.element.style.borderRadius = "";

        const canvas = glassContainer.element.querySelector("canvas");
        if (canvas) {
            canvas.style.borderRadius = "";
        }

        // Insert glass container at beginning
        element.insertBefore(glassContainer.element, element.firstChild);

        // NO POSITIONING CHANGES TO EXISTING CONTENT
        // The glass container uses z-index: -1 in CSS, so it's automatically behind content
        // We don't need to modify existing elements' positioning at all

        // Update state
        element.classList.remove("glass-loading");
        element.classList.add("glass-active");

        // Store reference for cleanup
        element._glassContainer = glassContainer;

        return glassContainer;
    } catch (error) {
        console.error("[SimplifiedGlass] Enhancement failed:", error);
        element.classList.remove("glass-loading");
        element.classList.add("glass-fallback", `glass-${componentType}`);
        return;
    }
}

/**
 * Create glass overlay that works with existing HTML
 * @param {HTMLElement} element - Parent element
 * @param {Object} options - Configuration options
 */
async function createGlassOverlay(element, options) {
    const { borderRadius, tintOpacity } = options;

    // Create sidebar container with right-only rounding for proper WebGL rendering
    const container = await Container.createSidebarContainerRightRounded({
        type: "rounded",
        borderRadius,
        tintOpacity,
    });

    if (!container) {
        return;
    }

    // NO BUTTON CREATION - pure background glass only
    // The container provides the glass background effect
    // Native HTML elements handle all interactions

    return container;
}

/**
 * Remove glass enhancement from element
 * @param {HTMLElement} element - Element to clean up
 */
export function removeGlassEnhancement(element) {
    if (element._glassContainer) {
        try {
            element._glassContainer.element.remove();
        } catch (error) {
            console.warn(
                "[SimplifiedGlass] Error removing glass container:",
                error,
            );
        }
        delete element._glassContainer;
    }

    // Reset element state
    element.classList.remove("glass-active", "glass-loading", "glass-fallback");
    delete element.dataset.glassActive;

    // Reset child positioning
    for (const child of element.children) {
        if (child.style.position === "relative" && child.style.zIndex === "1") {
            child.style.position = "";
            child.style.zIndex = "";
        }
    }
}

/**
 * Batch enhance multiple elements
 * @param {Array} elements - Array of {element, options} objects
 */
export async function batchEnhanceWithGlass(elements) {
    const results = [];

    for (const { element, options } of elements) {
        try {
            const result = await enhanceWithGlass(element, options);
            results.push({ element, result, success: !!result });
        } catch (error) {
            console.error(
                "[SimplifiedGlass] Batch enhancement failed for element:",
                element,
                error,
            );
            results.push({ element, result: undefined, success: false, error });
        }
    }

    return results;
}

/**
 * Check if element has glass enhancement
 * @param {HTMLElement} element - Element to check
 * @returns {Boolean} - Whether element has glass enhancement
 */
export function hasGlassEnhancement(element) {
    return (
        element.classList.contains("glass-active") && !!element._glassContainer
    );
}

/**
 * Get glass container for element
 * @param {HTMLElement} element - Element to get container for
 * @returns {Object|null} - Glass container or null
 */
export function getGlassContainer(element) {
    return element._glassContainer || undefined;
}
