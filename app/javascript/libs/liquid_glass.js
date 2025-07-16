import { Container } from "./container.js";
import { Button } from "./button.js";
import html2canvas from "html2canvas";
import { glassRenderManager } from "./glass_render_manager.js";
import { optimizedWebGLContextManager } from "./optimized_webgl_manager.js";
import { glassConfigManager } from "./glass_config_manager.js";

// Global initialization tracking to prevent multiple simultaneous initializations across all functions
const initializationTracker = new WeakSet();

// Optimized instance cache for better memory management
const instanceCache = new Map();

// Performance monitoring
const PerformanceMonitor = {
    renderCount: 0,
    averageRenderTime: 0,
    lastRenderTime: 0,
    slowRenderThreshold: 16.67, // 60fps threshold

    recordRender(duration) {
        this.renderCount++;
        this.averageRenderTime = (this.averageRenderTime + duration) / 2;
        this.lastRenderTime = duration;

        if (duration > this.slowRenderThreshold) {
            console.warn(
                `[PerformanceMonitor] Slow render detected: ${duration.toFixed(2)}ms`,
            );
        }
    },

    getStats() {
        return {
            totalRenders: this.renderCount,
            averageRenderTime: this.averageRenderTime.toFixed(2),
            lastRenderTime: this.lastRenderTime.toFixed(2),
            webglStats: optimizedWebGLContextManager.getStats(),
            configStats: glassConfigManager.getStats(),
        };
    },
};

// Legacy compatibility wrapper for WebGLContextManager
const WebGLContextManager = {
    get contexts() {
        return optimizedWebGLContextManager.contexts;
    },

    getContext(element) {
        return optimizedWebGLContextManager.getContext(element);
    },

    cleanup() {
        return optimizedWebGLContextManager.cleanup();
    },

    releaseContext(element) {
        return optimizedWebGLContextManager.releaseContext(element);
    },
};

// Backward compatibility WebGL debugger
const WebGLDebugger = {
    contextLossCount: 0,
    contextCreateCount: 0,

    monitorCanvas(canvas, identifier = "unknown") {
        // Enhanced monitoring with performance tracking
        if (!canvas) return;

        canvas.addEventListener("webglcontextlost", (event) => {
            this.contextLossCount++;
            console.error(`WebGL Debug - Context lost (${identifier}):`, {
                lossCount: this.contextLossCount,
                canvasSize: `${canvas.width}x${canvas.height}`,
                totalContexts: optimizedWebGLContextManager.contexts.size,
                event: event.type,
            });
            event.preventDefault();
        });

        canvas.addEventListener("webglcontextrestored", (event) => {
            console.log(`WebGL Debug - Context restored (${identifier}):`, {
                canvasSize: `${canvas.width}x${canvas.height}`,
                totalContexts: optimizedWebGLContextManager.contexts.size,
                event: event.type,
            });
        });
    },

    logContextCreation(canvas, identifier = "unknown") {
        this.contextCreateCount++;
        console.log(`WebGL Debug - Context created (${identifier}):`, {
            createCount: this.contextCreateCount,
            canvasSize: `${canvas.width}x${canvas.height}`,
            totalContexts: optimizedWebGLContextManager.contexts.size,
        });
    },
};

/**
 * Render a Liquid Glass navigation bar or sidebar into a given element.
 * @param {HTMLElement} element - The container element to render into.
 * @param {Array<{text: string, path: string, onClick?: function, buttonOptions?: object}>} navItems - Navigation items to render. Each item can have a custom onClick or buttonOptions.
 * @param {Object} [containerOptions] - Optional container options (borderRadius, tintOpacity, etc).
 * @param {Object} [renderOptions] - Rendering options
 * @param {boolean} [renderOptions.preserveOriginalHTML] - Whether to keep original HTML visible during load
 * @param {string} [renderOptions.originalContent] - Original HTML content to restore on cleanup
 * @param {string} [renderOptions.componentType] - Type of component being rendered
 *
 * Container Types Available:
 * - Container.createSidebarContainer(options) - For sidebars (no parallax)
 * - Container.createParallaxContainer(speed, options) - For parallax elements
 * - Container.createFixedContainer(options) - For fixed position elements
 * - new Container(options) - For custom configurations
 */
export async function renderLiquidGlassNav(
    element,
    navItems,
    containerOptions = {},
    renderOptions = {},
) {
    if (!element) throw new Error("No container element provided");

    // Prevent multiple initializations of the same element
    if (element._liquidGlassInstance) {
        console.warn(
            "Liquid glass already initialized on this element, skipping",
        );
        return element._liquidGlassInstance;
    }

    let glassContainer;
    const originalHTML = renderOptions.originalContent || element.innerHTML;

    try {
        // Save the original HTML for fallback or restoration

        // If preserveOriginalHTML is true, don't clear content initially
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = "";
        }

        // Enhanced container creation with explicit error handling
        try {
            glassContainer = await Container.createSidebarContainer({
                type: "rounded",
                borderRadius: 0,
                tintOpacity: 0.12,
                ...containerOptions,
            });
        } catch (containerError) {
            console.error(
                "[LiquidGlass] Container creation failed:",
                containerError,
            );
            throw new Error(
                `Glass container creation failed: ${containerError.message}`,
            );
        }

        // Enhanced validation of container creation
        if (!glassContainer) {
            console.warn("[LiquidGlass] Container creation returned null");
            throw new Error("Glass container creation returned null");
        }

        if (!glassContainer.element) {
            console.warn("[LiquidGlass] Container element is null");
            throw new Error("Glass container element is null");
        }

        // Check if the container has a valid canvas
        const canvas = glassContainer.element.querySelector("canvas");
        if (!canvas) {
            console.warn("[LiquidGlass] Container has no canvas element");
            throw new Error("Glass container has no canvas element");
        }

        // Test canvas context
        const canvasContext =
            canvas.getContext("webgl2") ||
            canvas.getContext("webgl") ||
            canvas.getContext("experimental-webgl");

        if (!canvasContext) {
            console.warn("[LiquidGlass] Canvas context creation failed");
            throw new Error("Canvas WebGL context creation failed");
        }

        if (canvasContext.isContextLost()) {
            console.warn("[LiquidGlass] Canvas context is lost");
            throw new Error("Canvas WebGL context is lost");
        }

        // Set up context loss monitoring
        canvas.addEventListener("webglcontextlost", (event) => {
            console.warn("[LiquidGlass] WebGL context lost for nav element");
            event.preventDefault();
            // Trigger fallback mode
            if (element && globalThis.glassFallbackMonitor !== undefined) {
                globalThis.glassFallbackMonitor.triggerGlobalFallback(
                    "WebGL context lost during runtime",
                );
            }
        });

        canvas.addEventListener("webglcontextrestored", () => {
            console.log("[LiquidGlass] WebGL context restored for nav element");
            // Could potentially retry glass effect here
        });

        glassContainer.element.style.flexDirection = "column";
        glassContainer.element.style.alignItems = "stretch";
        glassContainer.element.style.width = "100%";
        glassContainer.element.style.height = "100%";

        // If preserving original HTML, position glass container appropriately
        if (renderOptions.preserveOriginalHTML) {
            glassContainer.element.style.position = "absolute";
            glassContainer.element.style.top = "0";
            glassContainer.element.style.left = "0";
            glassContainer.element.style.zIndex = "1";

            // Make sure existing content is above glass
            const existingContent = element.querySelector(
                ".sidebar-contents, .nav-contents, .card-contents, .button-contents",
            );
            if (existingContent) {
                existingContent.style.position = "relative";
                existingContent.style.zIndex = "2";
            }
        }

        for (const item of navItems) {
            // Skip items without SVG for nav components
            if (
                !item.svg &&
                (renderOptions.componentType === "nav" ||
                    renderOptions.componentType === "sidebar")
            ) {
                console.error(`Nav item missing required SVG content:`, item);
                continue;
            }

            console.log(
                "Processing nav item:",
                item.text,
                "icon:",
                item.icon,
                "path:",
                item.path,
                "has SVG:",
                !!item.svg,
            );

            let button;
            try {
                button = new Button({
                    text: item.text || "", // Use provided text or empty
                    size: 18,
                    type: "pill",
                    onClick:
                        item.onClick ||
                        (() => {
                            globalThis.location.href = item.path;
                        }),
                    iconHTML: item.svg || "",
                    ...item.buttonOptions,
                });
            } catch (buttonError) {
                console.error(
                    "[LiquidGlass] Button creation failed:",
                    buttonError,
                );
                // Skip this button and continue with others
                continue;
            }

            // Validate button was created successfully
            if (!button || !button.element) {
                console.warn(
                    "[LiquidGlass] Button creation returned null for item:",
                    item.text,
                );
                continue;
            }

            // Check if button has a canvas
            const buttonCanvas = button.element.querySelector("canvas");
            if (buttonCanvas) {
                // Set up context loss monitoring for button
                buttonCanvas.addEventListener("webglcontextlost", (event) => {
                    console.warn(
                        "[LiquidGlass] WebGL context lost for button:",
                        item.text,
                    );
                    event.preventDefault();
                });
            }

            // Add data-path for navigation
            if (item.path) {
                button.element.dataset.path = item.path;
            }

            // If preserving original HTML, hide glass buttons initially
            if (renderOptions.preserveOriginalHTML) {
                button.element.style.opacity = "0";
                button.element.style.pointerEvents = "none";
            }

            console.log(
                "Created button with text:",
                button.text,
                "iconHTML present:",
                !!item.svg,
            );
            glassContainer.addChild(button);
        }

        if (renderOptions.preserveOriginalHTML) {
            // Insert glass container at the beginning so it's behind existing content
            element.insertBefore(glassContainer.element, element.firstChild);

            // Set up transition after glass effect is ready
            setTimeout(() => {
                const existingContent = element.querySelector(
                    ".sidebar-contents, .nav-contents, .card-contents, .button-contents",
                );
                const glassButtons = element.querySelectorAll(".glass-button");

                // Start transition
                if (existingContent) {
                    existingContent.style.transition = "opacity 300ms ease-out";
                    existingContent.style.opacity = "0";
                }

                for (const button of glassButtons) {
                    button.style.transition = "opacity 300ms ease-in";
                    button.style.opacity = "1";
                    button.style.pointerEvents = "auto";
                }

                // After transition, hide original content completely
                setTimeout(() => {
                    if (existingContent) {
                        existingContent.style.display = "none";
                    }
                }, 300);
            }, 100); // Small delay to ensure glass effect is ready
        } else {
            element.append(glassContainer.element);
        }

        // Store reference on DOM element for cleanup
        element._liquidGlassInstance = glassContainer;
        element._originalHTML = originalHTML;

        return glassContainer;
    } catch (error) {
        console.error("Error rendering liquid glass nav:", error);

        // Restore original content for fallback
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = renderOptions.originalContent || originalHTML;
        }

        // Add fallback class immediately
        element.classList.add("glass-fallback");

        // Dispatch fallback event for controllers to handle
        const fallbackEvent = new CustomEvent("glass:fallbackActivated", {
            detail: { error: error.message, element: element },
        });
        element.dispatchEvent(fallbackEvent);

        // Return on error, controller will handle graceful fallback
        return;
    }
}

/**
 * Optimized validation with caching for better performance
 * @param {HTMLElement} element - Element to test
 * @returns {boolean} - Whether initialization would succeed
 */
export function validateLiquidGlass(element) {
    // Cache validation results to avoid repeated expensive checks
    const cacheKey = element.tagName + element.className;
    if (instanceCache.has(cacheKey)) {
        const cached = instanceCache.get(cacheKey);
        if (Date.now() - cached.timestamp < 5000) {
            // 5 second cache
            return cached.valid;
        }
    }

    try {
        // Check basic requirements
        if (!element || !element.isConnected) {
            console.error(
                "Liquid glass validation failed: Element is null or not connected to DOM",
            );
            return false;
        }

        // Enhanced WebGL support check
        if (
            !globalThis.WebGLRenderingContext &&
            !globalThis.WebGL2RenderingContext
        ) {
            console.error(
                "Liquid glass validation failed: WebGL not supported",
            );
            return false;
        }

        // Test canvas creation capability
        const testCanvas = document.createElement("canvas");
        testCanvas.width = 32;
        testCanvas.height = 32;

        let gl;
        const contextOptions = {
            alpha: true,
            premultipliedAlpha: false,
            preserveDrawingBuffer: false,
            antialias: false,
            failIfMajorPerformanceCaveat: true, // Fail on software rendering
        };

        try {
            gl =
                testCanvas.getContext("webgl2", contextOptions) ||
                testCanvas.getContext("webgl", contextOptions) ||
                testCanvas.getContext("experimental-webgl", contextOptions);
        } catch (canvasError) {
            console.error(
                "Liquid glass validation failed: Canvas context creation threw error:",
                canvasError,
            );
            return false;
        }

        if (!gl) {
            console.error(
                "Liquid glass validation failed: WebGL context creation failed - canvas returned null",
            );
            return false;
        }

        // Enhanced context health check
        if (gl.isContextLost()) {
            console.error(
                "Liquid glass validation failed: WebGL context is lost immediately after creation",
            );
            return false;
        }

        // Test basic WebGL functionality
        try {
            const vertexShader = gl.createShader(gl.VERTEX_SHADER);
            if (!vertexShader) {
                console.error(
                    "Liquid glass validation failed: Cannot create vertex shader",
                );
                return false;
            }
            gl.deleteShader(vertexShader);

            // Test texture creation
            const texture = gl.createTexture();
            if (!texture) {
                console.error(
                    "Liquid glass validation failed: Cannot create texture",
                );
                return false;
            }
            gl.deleteTexture(texture);

            // Test framebuffer creation
            const framebuffer = gl.createFramebuffer();
            if (!framebuffer) {
                console.error(
                    "Liquid glass validation failed: Cannot create framebuffer",
                );
                return false;
            }
            gl.deleteFramebuffer(framebuffer);
        } catch (webglError) {
            console.error(
                "Liquid glass validation failed: WebGL functionality test failed:",
                webglError,
            );
            return false;
        }

        // Check maximum texture size
        const maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
        if (maxTextureSize < 512) {
            console.error(
                "Liquid glass validation failed: Maximum texture size too small:",
                maxTextureSize,
            );
            return false;
        }

        // Check html2canvas availability
        if (!html2canvas) {
            console.error(
                "Liquid glass validation failed: html2canvas not available",
            );
            return false;
        }

        // Test html2canvas basic functionality
        try {
            const testDiv = document.createElement("div");
            testDiv.style.width = "10px";
            testDiv.style.height = "10px";
            testDiv.style.background = "red";
            testDiv.style.position = "absolute";
            testDiv.style.top = "-1000px";
            document.body.append(testDiv);

            // Quick html2canvas test (don't await, just check if it starts)
            const canvasPromise = html2canvas(testDiv, {
                width: 10,
                height: 10,
                logging: false,
                useCORS: true,
            });

            testDiv.remove();

            if (!canvasPromise || typeof canvasPromise.then !== "function") {
                console.error(
                    "Liquid glass validation failed: html2canvas not functioning properly",
                );
                return false;
            }
        } catch (html2canvasError) {
            console.error(
                "Liquid glass validation failed: html2canvas test failed:",
                html2canvasError,
            );
            return false;
        }

        // Cache the result
        instanceCache.set(cacheKey, {
            valid: true,
            timestamp: Date.now(),
        });

        console.log("Liquid glass validation successful");
        return true;
    } catch (error) {
        console.error("Liquid glass validation failed with error:", error);

        // Cache the failure
        instanceCache.set(cacheKey, {
            valid: false,
            timestamp: Date.now(),
        });

        return false;
    }
}

/**
 * Create a parallax-aware liquid glass container for content with parallax effects
 * @param {HTMLElement} element - The container element
 * @param {number} parallaxSpeed - Parallax speed (0.5 = half speed, 1.0 = normal, 2.0 = double speed)
 * @param {Object} [options] - Additional container options
 */
export function createParallaxGlassContainer(
    element,
    parallaxSpeed = 0.5,
    options = {},
) {
    if (!element) throw new Error("No container element provided");

    const glassContainer = Container.createParallaxContainer(parallaxSpeed, {
        type: "rounded",
        borderRadius: 10,
        tintOpacity: 0.15,
        ...options,
    });

    element.innerHTML = "";
    element.append(glassContainer.element);

    return glassContainer;
}

/**
 * Create a liquid glass container for fixed position elements
 * @param {HTMLElement} element - The container element
 * @param {Object} [options] - Container options
 * @param {number} [options.backgroundParallaxSpeed=0.5] - Speed of background parallax elements to sync with
 */
export function createFixedGlassContainer(element, options = {}) {
    if (!element) throw new Error("No container element provided");

    const glassContainer = Container.createFixedContainer({
        type: "rounded",
        borderRadius: 10,
        tintOpacity: 0.1,
        ...options,
    });

    element.innerHTML = "";
    element.append(glassContainer.element);

    return glassContainer;
}

/**
 * Render a Liquid Glass sidebar with only right corners rounded (for left-edge sidebars)
 * @param {HTMLElement} element - The container element to render into.
 * @param {Array} navItems - Navigation items to render
 * @param {Object} [containerOptions] - Optional container options
 * @param {Object} [renderOptions] - Rendering options
 * @param {boolean} [renderOptions.preserveOriginalHTML] - Whether to keep original HTML visible during load
 * @param {string} [renderOptions.originalContent] - Original HTML content to restore on cleanup
 */
export async function renderLiquidGlassSidebarRightRounded(
    element,
    navItems,
    containerOptions = {},
    renderOptions = {},
) {
    if (!element) throw new Error("No container element provided");

    // Prevent multiple initializations
    if (element._liquidGlassInstance) {
        console.warn(
            "Liquid glass already initialized on this element, skipping",
        );
        return element._liquidGlassInstance;
    }

    // Save the original HTML for fallback or restoration
    const originalHTML = renderOptions.originalContent || element.innerHTML;

    try {
        // If preserveOriginalHTML is true, create glass container without clearing content initially
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = "";
        }

        const glassContainer =
            await Container.createSidebarContainerRightRounded({
                type: "rounded",
                borderRadius: 0,
                tintOpacity: 0.12,
                ...containerOptions,
            });

        // Same setup as regular sidebar...
        glassContainer.element.style.flexDirection = "column";
        glassContainer.element.style.alignItems = "stretch";
        glassContainer.element.style.width = "100%";
        glassContainer.element.style.height = "100%";

        // If preserving original HTML, position glass container behind existing content
        if (renderOptions.preserveOriginalHTML) {
            glassContainer.element.style.position = "absolute";
            glassContainer.element.style.top = "0";
            glassContainer.element.style.left = "0";
            glassContainer.element.style.zIndex = "1";

            // Make sure existing content is above glass
            const existingContent = element.querySelector(".sidebar-contents");
            if (existingContent) {
                existingContent.style.position = "relative";
                existingContent.style.zIndex = "2";
            }
        }

        // Add navigation items (same as regular renderLiquidGlassNav)
        for (const item of navItems) {
            // Require SVG content to be present
            if (!item.svg) {
                console.error(`Nav item missing required SVG content:`, item);
                continue; // Skip items without SVG content
            }

            const button = new Button({
                iconHTML: item.svg,
                text: "", // Icons only for sidebar
                size: 18, // Add the missing size parameter
                type: "pill",
                onClick:
                    item.onClick ||
                    (() => {
                        globalThis.location.href = item.path;
                    }),
                path: item.path,
                label: item.label,
                method: item.method,
                ...item.buttonOptions,
            });
            // Add data-path for current-page detection
            button.element.dataset.path = item.path;

            // If preserving original HTML, hide glass buttons initially
            if (renderOptions.preserveOriginalHTML) {
                button.element.style.opacity = "0";
                button.element.style.pointerEvents = "none";
            }

            glassContainer.addChild(button);
        }

        if (renderOptions.preserveOriginalHTML) {
            // Insert glass container at the beginning so it's behind existing content
            element.insertBefore(glassContainer.element, element.firstChild);

            // After a short delay, fade in glass buttons and fade out original content
            setTimeout(() => {
                const existingContent =
                    element.querySelector(".sidebar-contents");
                const glassButtons = element.querySelectorAll(".glass-button");

                // Start transition
                if (existingContent) {
                    existingContent.style.transition = "opacity 300ms ease-out";
                    existingContent.style.opacity = "0";
                }

                for (const button of glassButtons) {
                    button.style.transition = "opacity 300ms ease-in";
                    button.style.opacity = "1";
                    button.style.pointerEvents = "auto";
                }

                // After transition, hide original content completely
                setTimeout(() => {
                    if (existingContent) {
                        existingContent.style.display = "none";
                    }
                }, 300);
            }, 100); // Small delay to ensure glass effect is ready
        } else {
            element.append(glassContainer.element);
        }

        element._liquidGlassInstance = glassContainer;
        element._originalHTML = originalHTML;

        return glassContainer;
    } catch (error) {
        console.error("Error creating liquid glass sidebar:", error);
        // If preserveOriginalHTML was true, we don't need to restore since content is still there
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = renderOptions.originalContent || originalHTML;
        }
        throw error;
    }
}

/**
 * Render a Liquid Glass drawer component
 * @param {HTMLElement} element - The container element to render into.
 * @param {Object} [containerOptions] - Optional container options
 * @param {Object} [renderOptions] - Rendering options
 * @param {boolean} [renderOptions.preserveOriginalHTML] - Whether to keep original HTML visible during load
 * @param {string} [renderOptions.originalContent] - Original HTML content to restore on cleanup
 * @param {boolean} [renderOptions.expanded] - Whether drawer is expanded
 * @param {string} [renderOptions.cornerRounding] - Corner rounding style
 */
export async function renderLiquidGlassDrawer(
    element,
    containerOptions = {},
    renderOptions = {},
) {
    if (!element) throw new Error("No container element provided");

    // Prevent multiple initializations
    if (element._liquidGlassInstance) {
        console.warn(
            "Liquid glass already initialized on this element, skipping",
        );
        return element._liquidGlassInstance;
    }

    // Use global initialization tracker to prevent any simultaneous initialization
    if (initializationTracker.has(element)) {
        console.warn(
            "Liquid glass already initializing globally on this element, skipping",
        );
        return;
    }
    initializationTracker.add(element);

    // Set a flag to prevent race conditions during initialization
    if (element._liquidGlassInitializing) {
        console.warn(
            "Liquid glass already initializing on this element, skipping",
        );
        initializationTracker.delete(element);
        return;
    }
    element._liquidGlassInitializing = true;

    // Validate WebGL support before proceeding
    if (!validateLiquidGlass(element)) {
        console.error("Liquid glass validation failed, cannot render drawer");
        element._liquidGlassInitializing = false;
        initializationTracker.delete(element);
        throw new Error(
            "WebGL or html2canvas not available - liquid glass cannot be rendered",
        );
    }

    // Save the original HTML for fallback or restoration
    const originalHTML = renderOptions.originalContent || element.innerHTML;

    try {
        // Find the actual drawer element (the one with .drawer class)
        const drawerElement = element.querySelector(".drawer") || element;

        // DON'T change the drawer positioning at all - it has position: fixed in CSS
        // Instead, we'll create a wrapper for the glass effect that doesn't interfere with layout

        // If preserveOriginalHTML is true, don't clear content initially
        if (!renderOptions.preserveOriginalHTML && drawerElement) {
            drawerElement.innerHTML = "";
        }

        // Create container with drawer-specific options - create a proper container like sidebar does
        console.log("Creating glass container with options:", {
            type: "rounded",
            borderRadius: containerOptions.borderRadius || 20,
            tintOpacity: containerOptions.tintOpacity || 0.1,
            ...containerOptions,
        });

        const glassContainer = await Container.createSidebarContainer({
            type: "rounded",
            borderRadius: containerOptions.borderRadius || 20,
            tintOpacity: containerOptions.tintOpacity || 0.1,
            ...containerOptions,
        });

        // Add comprehensive WebGL debugging for Container initialization
        console.log(
            "WebGL Debug - Container created, checking WebGL state before DOM insertion:",
            {
                containerExists: !!glassContainer,
                hasElement: !!glassContainer?.element,
                webglContextsActive: WebGLContextManager.contexts.size,
                webglSupported: !!globalThis.WebGLRenderingContext,
                timestamp: Date.now(),
            },
        );

        // Monitor WebGL context loss events on the container element
        if (glassContainer && glassContainer.element) {
            const canvas = glassContainer.element.querySelector("canvas");
            if (canvas) {
                console.log("WebGL Debug - Canvas found in new container:", {
                    canvasWidth: canvas.width,
                    canvasHeight: canvas.height,
                    hasWebGLContext: !!optimizedWebGLContextManager.getContext(
                        canvas.parentElement,
                        canvas,
                    ),
                });

                // Monitor context loss and log context creation
                WebGLDebugger.monitorCanvas(canvas, "drawer-container");
                WebGLDebugger.logContextCreation(canvas, "drawer-container");
            } else {
                console.warn(
                    "WebGL Debug - No canvas found in newly created container",
                );
            }
        }

        console.log("Container creation result:", {
            containerCreated: !!glassContainer,
            containerType: glassContainer?.constructor?.name,
            hasElement: !!glassContainer?.element,
            elementTagName: glassContainer?.element?.tagName,
            elementId: glassContainer?.element?.id,
            elementClasses: glassContainer?.element?.className,
            isConnected: glassContainer?.element?.isConnected,
        });

        // Ensure glass container was created successfully
        if (!glassContainer || !glassContainer.element) {
            console.error("Failed to create glass container for drawer");
            console.error(
                "Container.createSidebarContainer returned:",
                glassContainer,
            );
            throw new Error("Glass container creation failed");
        }

        console.log("Glass container created successfully:", {
            hasElement: !!glassContainer.element,
            elementTagName: glassContainer.element?.tagName,
            elementId: glassContainer.element?.id,
            elementClasses: glassContainer.element?.className,
        });

        // Configure for drawer layout with proper WebGL canvas sizing
        // The glass container needs to fill the drawer without interfering with its positioning
        glassContainer.element.style.width = "100%";
        glassContainer.element.style.height = "100%";
        glassContainer.element.style.position = "absolute";
        glassContainer.element.style.top = "0";
        glassContainer.element.style.left = "0";
        glassContainer.element.style.right = "0";
        glassContainer.element.style.bottom = "0";
        glassContainer.element.style.flexDirection = "column";
        glassContainer.element.style.alignItems = "stretch";
        glassContainer.element.style.zIndex = "0"; // Behind content
        glassContainer.element.style.pointerEvents = "none"; // Don't interfere with drawer interactions

        // Apply drawer-specific border radius directly to the container
        const borderRadius = getBorderRadiusForCorners(
            containerOptions.borderRadius || 20,
            renderOptions.cornerRounding || "top",
        );
        glassContainer.element.style.borderRadius = borderRadius;

        // Create a single invisible button to ensure WebGL canvas coverage
        // Instead of multiple buttons which create too many WebGL contexts
        const invisibleButton = new Button({
            text: "",
            size: 18,
            type: "pill",
            onClick: () => {}, // No-op
            iconHTML: "", // No icon needed
            buttonOptions: {
                warp: false,
            },
        });

        // Make button completely transparent and non-interactive but positioned to cover drawer
        invisibleButton.element.style.opacity = "0";
        invisibleButton.element.style.pointerEvents = "none";
        invisibleButton.element.style.position = "relative";
        invisibleButton.element.style.margin = "2px";
        invisibleButton.element.style.width = "100%";
        invisibleButton.element.style.height = "100%";
        invisibleButton.element.style.minWidth = "40px";
        invisibleButton.element.style.minHeight = "40px";

        glassContainer.addChild(invisibleButton);

        // Create a reference holder for the container to prevent garbage collection
        const containerReference = {
            container: glassContainer,
            element: glassContainer.element,
            isInitializing: true,
        };

        // Store the container reference on the DOM element to prevent GC
        if (glassContainer.element) {
            glassContainer.element._liquidGlassContainer = containerReference;
        }

        // DON'T schedule canvas setup yet - wait until after DOM insertion
        // The element needs to be connected to the DOM before canvas setup

        // If preserving original HTML, position glass container appropriately
        if (renderOptions.preserveOriginalHTML && drawerElement) {
            // Make sure existing content is above glass
            const existingHeader =
                drawerElement.querySelector(".drawer-header");
            const existingContents =
                drawerElement.querySelector(".drawer-contents");

            if (existingHeader) {
                existingHeader.style.position = "relative";
                existingHeader.style.zIndex = "2";
            }

            if (existingContents) {
                existingContents.style.position = "relative";
                existingContents.style.zIndex = "2";
            }

            // DON'T change drawer positioning - it's handled by CSS
            // Just insert the glass container at the beginning
            drawerElement.insertBefore(
                glassContainer.element,
                drawerElement.firstChild,
            );

            // WebGL Debug - Check state immediately after DOM insertion
            console.log("WebGL Debug - Container inserted into DOM:", {
                elementConnected: glassContainer.element.isConnected,
                elementParent: glassContainer.element.parentNode?.tagName,
                webglContextsActive: WebGLContextManager.contexts.size,
                containerHasCanvas:
                    !!glassContainer.element.querySelector("canvas"),
            });

            // Monitor for Container self-destruction
            const originalElement = glassContainer.element;
            setTimeout(() => {
                console.log(
                    "WebGL Debug - Container state 100ms after DOM insertion:",
                    {
                        elementStillExists:
                            originalElement === glassContainer.element,
                        elementConnected: glassContainer.element?.isConnected,
                        elementParent:
                            glassContainer.element?.parentNode?.tagName,
                        containerHasCanvas:
                            !!glassContainer.element?.querySelector("canvas"),
                    },
                );
            }, 100);

            setTimeout(() => {
                console.log(
                    "WebGL Debug - Container state 500ms after DOM insertion:",
                    {
                        elementStillExists:
                            originalElement === glassContainer.element,
                        elementConnected: glassContainer.element?.isConnected,
                        elementParent:
                            glassContainer.element?.parentNode?.tagName,
                        containerHasCanvas:
                            !!glassContainer.element?.querySelector("canvas"),
                    },
                );
            }, 500);

            // Set up transition after WebGL glass effect is ready
            setTimeout(() => {
                const existingHeader =
                    drawerElement.querySelector(".drawer-header");
                const drawerContentContainer = drawerElement.querySelector(
                    ".drawer-content-container",
                );

                // Apply minimal styling to complement WebGL glass background
                if (existingHeader) {
                    existingHeader.style.transition =
                        "background-color 300ms ease, border-bottom 300ms ease";
                    existingHeader.style.backgroundColor =
                        "rgba(255, 255, 255, 0.05)";
                    existingHeader.style.borderBottom =
                        "1px solid rgba(255, 255, 255, 0.1)";
                }

                // Style the content container to complement WebGL glass
                if (drawerContentContainer) {
                    drawerContentContainer.style.transition =
                        "background-color 300ms ease";
                    drawerContentContainer.style.backgroundColor =
                        "rgba(255, 255, 255, 0.03)";
                }

                // Remove any conflicting background from the drawer itself since WebGL provides the glass
                drawerElement.style.background = "transparent";
                drawerElement.style.backdropFilter = "none";
                drawerElement.style.backgroundColor = "transparent";
            }, 200); // Longer delay to ensure WebGL is fully ready
        } else if (drawerElement) {
            drawerElement.append(glassContainer.element);

            // WebGL Debug - Check state immediately after DOM insertion (non-preserve path)
            console.log(
                "WebGL Debug - Container appended to DOM (non-preserve):",
                {
                    elementConnected: glassContainer.element.isConnected,
                    elementParent: glassContainer.element.parentNode?.tagName,
                    webglContextsActive: WebGLContextManager.contexts.size,
                    containerHasCanvas:
                        !!glassContainer.element.querySelector("canvas"),
                },
            );
        }

        // NOW that the element is connected to DOM, set up canvas styling
        const setupCanvas = (container) => {
            console.log("setupCanvas called with container:", {
                containerExists: !!container,
                containerType: container?.constructor?.name,
                hasElement: !!container?.element,
                elementType: container?.element?.tagName,
                elementConnected: container?.element?.isConnected,
                elementParent: container?.element?.parentNode?.tagName,
                timestamp: Date.now(),
            });

            // Use the passed container parameter instead of closure variable
            if (!container || !container.element) {
                console.error(
                    "Glass container became null during canvas setup",
                );
                console.error("Debug info:", {
                    containerIsNull: !container,
                    elementIsNull: !container?.element,
                    containerKeys: container ? Object.keys(container) : "N/A",
                    stackTrace: new Error("Stack trace for debugging").stack,
                });
                return;
            }

            console.log("Container validation passed, searching for canvas...");
            const canvas = container.element.querySelector("canvas");
            console.log("Canvas search result:", {
                canvasFound: !!canvas,
                canvasTagName: canvas?.tagName,
                canvasParent: canvas?.parentNode?.tagName,
                containerHTML:
                    container.element.innerHTML.slice(0, 200) + "...",
            });

            if (canvas) {
                console.log("Canvas found, applying drawer styling:", {
                    canvasWidth: canvas.width,
                    canvasHeight: canvas.height,
                    clientWidth: canvas.clientWidth,
                    clientHeight: canvas.clientHeight,
                    borderRadius: borderRadius,
                });

                // Ensure canvas matches drawer dimensions and corner rounding
                canvas.style.borderRadius = borderRadius;
                canvas.style.width = "100%";
                canvas.style.height = "100%";
                canvas.style.position = "absolute";
                canvas.style.top = "0";
                canvas.style.left = "0";
                canvas.style.zIndex = "0"; // Behind content

                // Get WebGL context through optimized manager
                const context = optimizedWebGLContextManager.getContext(
                    element,
                    canvas,
                );
                if (context) {
                    console.log("WebGL context acquired successfully:", {
                        contextType: context.constructor.name,
                        maxTextureSize: context.getParameter(
                            context.MAX_TEXTURE_SIZE,
                        ),
                        renderer: context.getParameter(context.RENDERER),
                        vendor: context.getParameter(context.VENDOR),
                        version: context.getParameter(context.VERSION),
                    });
                    context.viewport(0, 0, canvas.width, canvas.height);
                } else {
                    console.error(
                        "Failed to acquire WebGL context from canvas",
                    );
                    console.error("Canvas details:", {
                        tagName: canvas.tagName,
                        width: canvas.width,
                        height: canvas.height,
                        getContext: typeof canvas.getContext,
                    });
                }
            } else {
                console.error("No canvas found in glass container");
                console.error(
                    "Glass container contents:",
                    container.element?.innerHTML || "element is null",
                );
            }
        };

        console.log(
            "About to schedule canvas setup AFTER DOM insertion with container:",
            {
                containerExists: !!glassContainer,
                hasElement: !!glassContainer?.element,
                elementId: glassContainer?.element?.id,
                elementClasses: glassContainer?.element?.className,
                elementConnected: glassContainer?.element?.isConnected,
            },
        );

        // Add a safety check to prevent scheduling if container is already compromised
        if (
            !glassContainer ||
            !glassContainer.element ||
            !glassContainer.element.isConnected
        ) {
            console.error(
                "Container element is already compromised before scheduling canvas setup",
            );
            return glassContainer;
        }

        // Retry mechanism for when Container WebGL initialization fails
        const retryCanvasSetup = (attempt = 1, maxAttempts = 3) => {
            console.log(`Canvas setup attempt ${attempt}/${maxAttempts}`);

            setTimeout(() => {
                // Use the reference holder to get the container
                let currentContainer = containerReference.container;
                let currentElement = containerReference.element;

                // If the container was destroyed but element still exists, recreate the container wrapper
                if (
                    (!currentContainer || currentContainer.isDestroyed) &&
                    currentElement &&
                    currentElement.isConnected
                ) {
                    console.log(
                        "Container was destroyed but element exists, creating wrapper for canvas access",
                    );
                    // Create a minimal wrapper that allows us to access the canvas
                    currentContainer = {
                        element: currentElement,
                        type: glassContainer.type || "rounded",
                        borderRadius: glassContainer.borderRadius || 20,
                    };
                }

                console.log(
                    `Timeout callback AFTER DOM insertion (attempt ${attempt}), container status:`,
                    {
                        containerExists: !!currentContainer,
                        containerDestroyed: currentContainer?.isDestroyed,
                        hasElement: !!currentContainer?.element,
                        elementConnected:
                            currentContainer?.element?.isConnected,
                        elementParent:
                            currentContainer?.element?.parentNode?.tagName,
                        hasCanvas:
                            !!currentContainer?.element?.querySelector(
                                "canvas",
                            ),
                    },
                );

                // If we have a valid element with a canvas, proceed with setup
                if (
                    currentContainer &&
                    currentContainer.element &&
                    currentContainer.element.isConnected
                ) {
                    const canvas =
                        currentContainer.element.querySelector("canvas");
                    if (canvas) {
                        setupCanvas(currentContainer);
                        containerReference.isInitializing = false;
                    } else if (attempt < maxAttempts) {
                        console.warn(
                            `No canvas found on attempt ${attempt}, retrying...`,
                        );
                        retryCanvasSetup(attempt + 1, maxAttempts);
                    } else {
                        console.warn("No canvas found after all retries");
                        containerReference.isInitializing = false;
                    }
                }
                // If element was destroyed and we haven't exceeded max attempts, try again
                else if (attempt < maxAttempts) {
                    console.warn(
                        `Container/element destroyed on attempt ${attempt}, retrying...`,
                    );
                    retryCanvasSetup(attempt + 1, maxAttempts);
                }
                // If we've exhausted retries, accept that WebGL failed and continue
                else {
                    console.warn(
                        "Container WebGL initialization failed after all retries, continuing without canvas styling",
                    );
                    console.warn(
                        "Glass effect will still work but canvas styling will be skipped",
                    );
                    containerReference.isInitializing = false;
                }
            }, 300 * attempt); // Increase delay with each attempt
        };

        // Add a method to check if Container finished WebGL initialization
        const waitForContainerInit = (callback, maxWait = 2000) => {
            const startTime = Date.now();

            const checkInterval = setInterval(() => {
                const elapsed = Date.now() - startTime;

                // Check for ANY active container in the DOM, not just the original reference
                const activeContainers =
                    element.querySelectorAll(".glass-container");
                let activeContainer;

                // Find the container with a canvas (the main drawer container)
                for (const container of activeContainers) {
                    if (container.querySelector("canvas")) {
                        activeContainer = container;
                        break;
                    }
                }

                // Check if we have an active container with WebGL initialized
                const isReady =
                    activeContainer &&
                    (activeContainer._liquidGlassContainer?.container
                        ?.webglInitialized || // WebGL init complete
                        elapsed > maxWait); // Timeout

                console.log("Waiting for Container initialization:", {
                    elapsed: elapsed,
                    isReady: isReady,
                    activeContainers: activeContainers.length,
                    hasActiveContainer: !!activeContainer,
                    webglInitialized:
                        activeContainer?._liquidGlassContainer?.container
                            ?.webglInitialized,
                });

                if (isReady || elapsed > maxWait) {
                    clearInterval(checkInterval);

                    // Update our container reference to the active one
                    if (
                        activeContainer &&
                        activeContainer._liquidGlassContainer
                    ) {
                        containerReference.container =
                            activeContainer._liquidGlassContainer.container;
                        containerReference.element = activeContainer;
                    }

                    callback();
                }
            }, 50); // Check every 50ms
        };

        // Wait for container initialization before scheduling canvas setup
        waitForContainerInit(() => {
            console.log(
                "Container initialization phase complete, scheduling canvas setup",
            );

            // Check for any active container in the DOM
            const activeContainers =
                element.querySelectorAll(".glass-container");
            let activeContainer;

            // Find the container with a canvas (the main drawer container)
            for (const container of activeContainers) {
                if (container.querySelector("canvas")) {
                    activeContainer = container;
                    break;
                }
            }

            // Proceed if we have an active container with WebGL
            if (
                activeContainer &&
                activeContainer._liquidGlassContainer?.container
            ) {
                console.log(
                    "Found active container with WebGL, proceeding with canvas setup",
                );
                retryCanvasSetup();
            } else if (activeContainer) {
                console.log(
                    "Found active container without WebGL reference, proceeding anyway",
                );
                retryCanvasSetup();
            } else {
                console.warn(
                    "No active container found, skipping canvas setup",
                );
            }
        });

        // Start the retry mechanism
        // retryCanvasSetup()

        // Store reference on DOM element for cleanup
        element._liquidGlassInstance = glassContainer;
        element._originalHTML = originalHTML;
        element._liquidGlassInitializing = false; // Clear initialization flag
        initializationTracker.delete(element); // Remove from global tracker

        // Add cleanup listener for when element is removed
        const cleanup = () => {
            WebGLContextManager.releaseContext(element);
            if (element._liquidGlassInstance) {
                element._liquidGlassInstance = undefined;
            }
            element._liquidGlassInitializing = false;
            initializationTracker.delete(element);
        };

        // Clean up when element is removed from DOM
        const observer = new MutationObserver((mutations) => {
            for (const mutation of mutations) {
                if (mutation.type === "childList") {
                    for (const node of mutation.removedNodes) {
                        if (
                            node === element ||
                            (node.contains && node.contains(element))
                        ) {
                            cleanup();
                            observer.disconnect();
                        }
                    }
                }
            }
        });

        if (element.parentNode) {
            observer.observe(element.parentNode, {
                childList: true,
                subtree: true,
            });
        }

        return glassContainer;
    } catch (error) {
        console.error("Error creating liquid glass drawer:", error);
        element._liquidGlassInitializing = false; // Clear flag on error
        initializationTracker.delete(element); // Remove from global tracker
        // If preserveOriginalHTML was true, we don't need to restore since content is still there
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = renderOptions.originalContent || originalHTML;
        }
        throw error;
    }
}

/**
 * Get CSS border-radius string for drawer corners
 */
function getBorderRadiusForCorners(radius, cornerRounding = "top") {
    switch (cornerRounding) {
        case "top": {
            return `${radius}px ${radius}px 0 0`;
        }
        case "bottom": {
            return `0 0 ${radius}px ${radius}px`;
        }
        case "left": {
            return `${radius}px 0 0 ${radius}px`;
        }
        case "right": {
            return `0 ${radius}px ${radius}px 0`;
        }
        case "all": {
            return `${radius}px`;
        }
        default: {
            return `${radius}px ${radius}px 0 0`;
        }
    }
}

/**
 * Performance monitoring and debugging utilities
 */
export function getGlassPerformanceStats() {
    return PerformanceMonitor.getStats();
}

/**
 * Enable debug mode for glass components
 */
export function enableGlassDebugMode() {
    Container.enableDebug();
    console.log(
        "[LiquidGlass] Debug mode enabled - performance monitoring active",
    );
}

/**
 * Disable debug mode for better performance
 */
export function disableGlassDebugMode() {
    Container.disableDebug();
    console.log("[LiquidGlass] Debug mode disabled");
}

/**
 * Global cleanup function for all glass components
 */
export function cleanupAllGlassComponents() {
    console.log("[LiquidGlass] Starting global cleanup...");

    // Stop the render manager
    glassRenderManager.destroy();

    // Clean up WebGL contexts
    optimizedWebGLContextManager.destroy();

    // Clean up config manager
    glassConfigManager.destroy();

    // Clear instance cache
    instanceCache.clear();

    // Clean up tracked initializations
    // Note: WeakSet doesn't have a clear method, but it will be garbage collected

    console.log("[LiquidGlass] Global cleanup complete");
}

/**
 * Optimize existing glass components by updating their render strategy
 */
export function optimizeExistingGlassComponents() {
    console.log("[LiquidGlass] Optimizing existing components...");

    let optimizedCount = 0;

    // Find all elements with glass components
    const glassElements = document.querySelectorAll(
        '[data-glass-active="true"]',
    );

    for (const element of glassElements) {
        try {
            // Register with optimized render manager if not already registered
            const instance = element._liquidGlassInstance;
            if (instance && !glassRenderManager.instances.has(instance)) {
                // Add render manager integration
                instance.needsRender = true;
                instance.renderFrame = function () {
                    if (this.render && !this.isDestroyed) {
                        const start = performance.now();
                        this.render();
                        const duration = performance.now() - start;
                        PerformanceMonitor.recordRender(duration);
                    }
                };

                glassRenderManager.register(instance);
                optimizedCount++;
            }
        } catch (error) {
            console.warn("[LiquidGlass] Failed to optimize component:", error);
        }
    }

    console.log(
        `[LiquidGlass] Optimized ${optimizedCount} existing components`,
    );
    return optimizedCount;
}

/**
 * Batch update multiple glass components efficiently
 */
export function batchUpdateGlassComponents(updates) {
    glassConfigManager.scheduleBatchUpdate(updates);
}

/**
 * Monitor glass performance and provide recommendations
 */
export function analyzeGlassPerformance() {
    const stats = getGlassPerformanceStats();
    const recommendations = [];

    if (stats.averageRenderTime > 16.67) {
        recommendations.push(
            "Consider reducing tint opacity or border radius for better performance",
        );
    }

    if (stats.webglStats.activeContexts > 4) {
        recommendations.push(
            "Too many active WebGL contexts - consider reducing concurrent glass effects",
        );
    }

    if (stats.configStats.pendingUpdates > 5) {
        recommendations.push(
            "Many pending config updates - batch updates may improve performance",
        );
    }

    return {
        stats,
        recommendations,
        healthScore: Math.max(
            0,
            100 -
                stats.averageRenderTime * 2 -
                stats.webglStats.activeContexts * 5,
        ),
    };
}

// Auto-optimize existing components when this module loads
if (typeof globalThis !== "undefined") {
    // Wait for DOM to be ready
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", () => {
            setTimeout(optimizeExistingGlassComponents, 1000);
        });
    } else {
        setTimeout(optimizeExistingGlassComponents, 1000);
    }

    // Clean up on page unload
    window.addEventListener("beforeunload", cleanupAllGlassComponents);
}
