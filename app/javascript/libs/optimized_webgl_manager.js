// Optimized WebGL Context Manager with pooling and better resource management
class OptimizedWebGLContextManager {
    constructor() {
        this.contexts = new Map();
        this.contextPool = [];
        this.maxContexts = 16; // Increased for scalability - can support many more glass effects
        this.maxPoolSize = 8; // Increased pool size for better reuse
        this.contextLossCount = 0;
        this.contextCreateCount = 0;

        // Shared resources for efficiency
        this.sharedCanvas = null;
        this.sharedTextures = new Map();
        this.texturePool = [];
        this.maxTexturePoolSize = 20;
    }

    getContext(element, canvasElement = null) {
        // First check if we have an existing context for this element
        const existingContext = this.contexts.get(element);
        if (existingContext && !existingContext.isContextLost()) {
            return existingContext;
        }

        // Clean up any lost contexts
        this.cleanup();

        // Try to reuse a context from the pool
        if (this.contextPool.length > 0) {
            const pooledContext = this.contextPool.pop();
            if (pooledContext && !pooledContext.isContextLost()) {
                this.contexts.set(element, pooledContext);
                console.log(
                    `[OptimizedWebGL] Reused pooled context (${this.contexts.size}/${this.maxContexts})`,
                );
                return pooledContext;
            }
        }

        // If we're at the limit, use LRU strategy to reuse contexts
        if (this.contexts.size >= this.maxContexts) {
            const oldestElement = this.contexts.keys().next().value;
            const oldestContext = this.contexts.get(oldestElement);
            this.contexts.delete(oldestElement);

            // Reset the context for reuse
            if (oldestContext && !oldestContext.isContextLost()) {
                // Clear the context state
                this.clearContextState(oldestContext);
                this.contexts.set(element, oldestContext);
                console.log(
                    `[OptimizedWebGL] Reused LRU context (${this.contexts.size}/${this.maxContexts})`,
                );
                return oldestContext;
            }
        }

        // Create new context as last resort
        const canvas = canvasElement || this.getSharedCanvas();
        const contextOptions = {
            preserveDrawingBuffer: true,
            alpha: true,
            premultipliedAlpha: false,
            antialias: false, // Disable for performance with many instances
            depth: false, // Not needed for 2D glass effects
            stencil: false, // Not needed for 2D glass effects
            powerPreference: "high-performance", // Request high-performance GPU
        };

        const gl =
            canvas.getContext("webgl", contextOptions) ||
            canvas.getContext("experimental-webgl", contextOptions);

        if (gl) {
            this.contexts.set(element, gl);
            this.contextCreateCount++;

            // Set up context loss handling
            this.setupContextLossHandling(canvas, gl);

            // Initialize shared resources
            this.initializeSharedResources(gl);

            console.log(
                `[OptimizedWebGL] Created new context (${this.contexts.size}/${this.maxContexts})`,
            );
            return gl;
        }

        console.error("[OptimizedWebGL] Failed to create WebGL context");
        return null;
    }

    setupContextLossHandling(canvas, gl) {
        canvas.addEventListener("webglcontextlost", (event) => {
            this.contextLossCount++;
            console.warn(
                `[OptimizedWebGL] Context lost (total: ${this.contextLossCount})`,
            );
            event.preventDefault();
        });

        canvas.addEventListener("webglcontextrestored", () => {
            console.log(`[OptimizedWebGL] Context restored`);
        });
    }

    releaseContext(element) {
        const context = this.contexts.get(element);
        if (context) {
            this.contexts.delete(element);

            // Add to pool for reuse if pool isn't full
            if (
                this.contextPool.length < this.maxPoolSize &&
                !context.isContextLost()
            ) {
                this.contextPool.push(context);
                console.log(
                    `[OptimizedWebGL] Added context to pool (pool size: ${this.contextPool.length})`,
                );
            } else {
                // Force lose the context if we can't pool it
                const loseContextExt =
                    context.getExtension("WEBGL_lose_context");
                if (loseContextExt) {
                    loseContextExt.loseContext();
                }
            }
        }
    }

    cleanup() {
        // Remove lost contexts and disconnected elements
        for (const [element, context] of this.contexts.entries()) {
            if (context.isContextLost() || !element.isConnected) {
                this.contexts.delete(element);
            }
        }

        // Clean up the pool
        this.contextPool = this.contextPool.filter(
            (context) => !context.isContextLost(),
        );
    }

    getStats() {
        return {
            activeContexts: this.contexts.size,
            pooledContexts: this.contextPool.length,
            totalCreated: this.contextCreateCount,
            totalLost: this.contextLossCount,
            maxContexts: this.maxContexts,
            texturePoolSize: this.texturePool.length,
            sharedResourcesActive: !!this.sharedCanvas,
            scalabilityMode: "high", // Indicates this is configured for many concurrent effects
        };
    }

    destroy() {
        // Force lose all contexts
        for (const context of this.contexts.values()) {
            const loseContextExt = context.getExtension("WEBGL_lose_context");
            if (loseContextExt) {
                loseContextExt.loseContext();
            }
        }

        // Clean up pool
        for (const context of this.contextPool) {
            const loseContextExt = context.getExtension("WEBGL_lose_context");
            if (loseContextExt) {
                loseContextExt.loseContext();
            }
        }

        this.contexts.clear();
        this.contextPool.length = 0;
    }

    getSharedCanvas() {
        if (!this.sharedCanvas) {
            this.sharedCanvas = document.createElement("canvas");
            // Set reasonable default size for shared canvas
            this.sharedCanvas.width = 512;
            this.sharedCanvas.height = 512;
        }
        return this.sharedCanvas;
    }

    clearContextState(gl) {
        // Clear WebGL state to prepare context for reuse
        try {
            gl.useProgram(null);
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
            gl.bindTexture(gl.TEXTURE_2D, null);
            gl.bindFramebuffer(gl.FRAMEBUFFER, null);
            gl.bindRenderbuffer(gl.RENDERBUFFER, null);

            // Clear any remaining state
            gl.clear(gl.COLOR_BUFFER_BIT);
        } catch (error) {
            console.warn(
                "[OptimizedWebGL] Error clearing context state:",
                error,
            );
        }
    }

    initializeSharedResources(gl) {
        // Initialize any shared resources that can be reused across contexts
        try {
            // Enable common WebGL features for glass effects
            gl.enable(gl.BLEND);
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

            // Set up common state
            gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
        } catch (error) {
            console.warn(
                "[OptimizedWebGL] Error initializing shared resources:",
                error,
            );
        }
    }

    // Texture pool management for better performance with many instances
    getPooledTexture(gl, width, height) {
        const key = `${width}x${height}`;

        if (this.texturePool.length > 0) {
            const texture = this.texturePool.pop();
            return texture;
        }

        // Create new texture if pool is empty
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            width,
            height,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            null,
        );
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        return texture;
    }

    returnTextureToPool(texture) {
        if (this.texturePool.length < this.maxTexturePoolSize) {
            this.texturePool.push(texture);
        }
        // If pool is full, texture will be garbage collected
    }
}

// Global singleton instance
export const optimizedWebGLContextManager = new OptimizedWebGLContextManager();
