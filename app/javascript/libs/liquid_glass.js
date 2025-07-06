import { Container } from "./container.js";
import { Button } from "./button.js";
import html2canvas from "html2canvas";

// Global initialization tracking to prevent multiple simultaneous initializations across all functions
const initializationTracker = new WeakSet();

// Global WebGL debugging and monitoring
const WebGLDebugger = {
    contextLossCount: 0,
    contextCreateCount: 0,

    monitorCanvas(canvas, identifier = "unknown") {
        if (!canvas) return;

        canvas.addEventListener("webglcontextlost", (event) => {
            this.contextLossCount++;
            console.error(`WebGL Debug - Context lost (${identifier}):`, {
                lossCount: this.contextLossCount,
                canvasSize: `${canvas.width}x${canvas.height}`,
                totalContexts: WebGLContextManager.contexts.size,
                event: event.type,
            });
            event.preventDefault();
        });

        canvas.addEventListener("webglcontextrestored", (event) => {
            console.log(`WebGL Debug - Context restored (${identifier}):`, {
                canvasSize: `${canvas.width}x${canvas.height}`,
                totalContexts: WebGLContextManager.contexts.size,
                event: event.type,
            });
        });
    },

    logContextCreation(canvas, identifier = "unknown") {
        this.contextCreateCount++;
        console.log(`WebGL Debug - Context created (${identifier}):`, {
            createCount: this.contextCreateCount,
            canvasSize: `${canvas.width}x${canvas.height}`,
            totalContexts: WebGLContextManager.contexts.size,
        });
    },
};

// WebGL context management to prevent context exhaustion
const WebGLContextManager = {
    contexts: new Map(),
    maxContexts: 8, // Conservative limit to prevent browser issues

    getContext(element) {
        const existingContext = this.contexts.get(element);
        if (existingContext && !existingContext.isContextLost()) {
            return existingContext;
        }

        // Clean up lost contexts
        this.cleanup();

        // If we're at the limit, reuse oldest context
        if (this.contexts.size >= this.maxContexts) {
            const oldestElement = this.contexts.keys().next().value;
            this.contexts.delete(oldestElement);
        }

        // Create new context
        const canvas = document.createElement("canvas");
        const gl =
            canvas.getContext("webgl", { preserveDrawingBuffer: true }) ||
            canvas.getContext("experimental-webgl", {
                preserveDrawingBuffer: true,
            });

        if (gl) {
            this.contexts.set(element, gl);
            console.log(
                `WebGL context created (${this.contexts.size}/${this.maxContexts})`,
            );

            // Enhanced WebGL debugging
            if (this.contexts.size > 4) {
                console.warn(
                    `WebGL Debug - High context count detected: ${this.contexts.size}`,
                );
            }
        } else {
            console.error("WebGL Debug - Failed to create WebGL context:", {
                webglSupported: !!window.WebGLRenderingContext,
                contextCount: this.contexts.size,
                canvasSupported: !!window.HTMLCanvasElement,
                maxContexts: this.maxContexts,
            });
        }

        return gl;
    },

    cleanup() {
        for (const [element, context] of this.contexts.entries()) {
            if (context.isContextLost() || !element.isConnected) {
                this.contexts.delete(element);
            }
        }
    },

    releaseContext(element) {
        const context = this.contexts.get(element);
        if (context) {
            const loseContextExt = context.getExtension("WEBGL_lose_context");
            if (loseContextExt) {
                loseContextExt.loseContext();
            }
            this.contexts.delete(element);
        }
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
export function renderLiquidGlassNav(
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

    try {
        // Save the original HTML for fallback or restoration
        const originalHTML = renderOptions.originalContent || element.innerHTML;

        // If preserveOriginalHTML is true, don't clear content initially
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = "";
        }

        const glassContainer = Container.createSidebarContainer({
            type: "rounded",
            borderRadius: 0,
            tintOpacity: 0.12,
            ...containerOptions,
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

            const button = new Button({
                text: item.text || "", // Use provided text or empty
                size: 18,
                type: "pill",
                onClick:
                    item.onClick ||
                    (() => {
                        globalThis.location.href = item.path;
                    }),
                iconHTML: item.svg || "",
                ...(item.buttonOptions || {}),
            });

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

                glassButtons.forEach((button) => {
                    button.style.transition = "opacity 300ms ease-in";
                    button.style.opacity = "1";
                    button.style.pointerEvents = "auto";
                });

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
        // If preserveOriginalHTML was true, we don't need to restore since content is still there
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = renderOptions.originalContent || originalHTML;
        }
        // Return null on error, controller will handle graceful fallback
        return null;
    }
}

/**
 * Validate that liquid glass can be initialized safely
 * @param {HTMLElement} element - Element to test
 * @returns {boolean} - Whether initialization would succeed
 */
export function validateLiquidGlass(element) {
    try {
        // Check basic requirements
        if (!element || !element.isConnected) {
            console.error(
                "Liquid glass validation failed: Element is null or not connected to DOM",
            );
            return false;
        }

        // Use WebGL context manager for testing
        const gl = WebGLContextManager.getContext(element);
        if (!gl) {
            console.error(
                "Liquid glass validation failed: WebGL not supported",
            );
            console.error("Browser WebGL support details:", {
                userAgent: navigator.userAgent,
                webglSupported: !!window.WebGLRenderingContext,
                webgl2Supported: !!window.WebGL2RenderingContext,
                canvasSupported: !!window.HTMLCanvasElement,
            });
            return false;
        }

        // Single context test instead of multiple
        if (gl.isContextLost()) {
            console.error(
                "Liquid glass validation failed: WebGL context is lost",
            );
            return false;
        }

        // Check for critical WebGL extensions
        const criticalExtensions = ["OES_texture_float"];
        const availableExtensions = gl.getSupportedExtensions();
        const missingCritical = criticalExtensions.filter(
            (ext) => !availableExtensions.includes(ext),
        );

        if (missingCritical.length > 0) {
            console.warn("Critical WebGL extensions missing:", missingCritical);
        }

        // Check html2canvas availability
        if (!html2canvas) {
            console.error(
                "Liquid glass validation failed: html2canvas not available",
            );
            return false;
        }

        console.log("Liquid glass validation successful:", {
            webglContextsActive: WebGLContextManager.contexts.size,
            webglExtensions: availableExtensions?.length || 0,
            maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
            renderer: gl.getParameter(gl.RENDERER),
            webglVersion: gl.getParameter(gl.VERSION),
            webglVendor: gl.getParameter(gl.VENDOR),
            maxViewportDims: gl.getParameter(gl.MAX_VIEWPORT_DIMS),
            maxRenderBufferSize: gl.getParameter(gl.MAX_RENDERBUFFER_SIZE),
            contextAttributes: gl.getContextAttributes(),
        });

        // Additional WebGL context monitoring
        console.log("WebGL Debug - Browser WebGL capabilities:", {
            webglSupported: !!window.WebGLRenderingContext,
            webgl2Supported: !!window.WebGL2RenderingContext,
            maxWebGLContexts: "unknown", // Browser-dependent
            currentContextCount: WebGLContextManager.contexts.size,
            userAgent: navigator.userAgent.substring(0, 100) + "...",
        });

        return true;
    } catch (error) {
        console.error("Liquid glass validation failed with exception:", error);
        console.error("Stack trace:", error.stack);
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
    element.appendChild(glassContainer.element);

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
    element.appendChild(glassContainer.element);

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
export function renderLiquidGlassSidebarRightRounded(
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

    try {
        // Save the original HTML for fallback or restoration
        const originalHTML = renderOptions.originalContent || element.innerHTML;

        // If preserveOriginalHTML is true, create glass container without clearing content initially
        if (!renderOptions.preserveOriginalHTML) {
            element.innerHTML = "";
        }

        const glassContainer = Container.createSidebarContainerRightRounded({
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
                ...(item.buttonOptions || {}),
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

                glassButtons.forEach((button) => {
                    button.style.transition = "opacity 300ms ease-in";
                    button.style.opacity = "1";
                    button.style.pointerEvents = "auto";
                });

                // After transition, hide original content completely
                setTimeout(() => {
                    if (existingContent) {
                        existingContent.style.display = "none";
                    }
                }, 300);
            }, 100); // Small delay to ensure glass effect is ready
        } else {
            element.appendChild(glassContainer.element);
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
export function renderLiquidGlassDrawer(
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
        return null;
    }
    initializationTracker.add(element);

    // Set a flag to prevent race conditions during initialization
    if (element._liquidGlassInitializing) {
        console.warn(
            "Liquid glass already initializing on this element, skipping",
        );
        initializationTracker.delete(element);
        return null;
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

    try {
        // Save the original HTML for fallback or restoration
        const originalHTML = renderOptions.originalContent || element.innerHTML;

        // Find the actual drawer element (the one with .drawer class)
        const drawerElement = element.querySelector(".drawer") || element;

        // DON'T change the drawer positioning at all - it has position: fixed in CSS
        // Instead, we'll create a wrapper for the glass effect that doesn't interfere with layout

        // If preserveOriginalHTML is true, don't clear content initially
        if (!renderOptions.preserveOriginalHTML) {
            if (drawerElement) {
                drawerElement.innerHTML = "";
            }
        }

        // Create container with drawer-specific options - create a proper container like sidebar does
        console.log("Creating glass container with options:", {
            type: "rounded",
            borderRadius: containerOptions.borderRadius || 20,
            tintOpacity: containerOptions.tintOpacity || 0.1,
            ...containerOptions,
        });

        const glassContainer = Container.createSidebarContainer({
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
                webglSupported: !!window.WebGLRenderingContext,
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
                    hasWebGLContext: !!(
                        canvas.getContext("webgl") ||
                        canvas.getContext("experimental-webgl")
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
        const containerRef = {
            container: glassContainer,
            element: glassContainer.element,
            isInitializing: true,
        };

        // Store the container reference on the DOM element to prevent GC
        if (glassContainer.element) {
            glassContainer.element._liquidGlassContainer = containerRef;
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
            drawerElement.appendChild(glassContainer.element);

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
                    stackTrace: new Error().stack,
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
                    container.element.innerHTML.substring(0, 200) + "...",
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

                // Force WebGL context to redraw with proper dimensions
                const context =
                    canvas.getContext("webgl") ||
                    canvas.getContext("experimental-webgl");
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
                let currentContainer = containerRef.container;
                let currentElement = containerRef.element;

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
                        containerRef.isInitializing = false;
                    } else if (attempt < maxAttempts) {
                        console.warn(
                            `No canvas found on attempt ${attempt}, retrying...`,
                        );
                        retryCanvasSetup(attempt + 1, maxAttempts);
                    } else {
                        console.warn("No canvas found after all retries");
                        containerRef.isInitializing = false;
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
                    containerRef.isInitializing = false;
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
                let activeContainer = null;

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
                        containerRef.container =
                            activeContainer._liquidGlassContainer.container;
                        containerRef.element = activeContainer;
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
            let activeContainer = null;

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
                element._liquidGlassInstance = null;
            }
            element._liquidGlassInitializing = false;
            initializationTracker.delete(element);
        };

        // Clean up when element is removed from DOM
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === "childList") {
                    mutation.removedNodes.forEach((node) => {
                        if (
                            node === element ||
                            (node.contains && node.contains(element))
                        ) {
                            cleanup();
                            observer.disconnect();
                        }
                    });
                }
            });
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
 * Get rounded corners configuration for drawer
 */
function getDrawerRoundedCorners(cornerRounding = "top") {
    const corners = {
        topLeft: false,
        topRight: false,
        bottomLeft: false,
        bottomRight: false,
    };

    switch (cornerRounding) {
        case "top": {
            corners.topLeft = true;
            corners.topRight = true;
            break;
        }
        case "bottom": {
            corners.bottomLeft = true;
            corners.bottomRight = true;
            break;
        }
        case "left": {
            corners.topLeft = true;
            corners.bottomLeft = true;
            break;
        }
        case "right": {
            corners.topRight = true;
            corners.bottomRight = true;
            break;
        }
        case "all": {
            corners.topLeft = true;
            corners.topRight = true;
            corners.bottomLeft = true;
            corners.bottomRight = true;
            break;
        }
    }

    return corners;
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
